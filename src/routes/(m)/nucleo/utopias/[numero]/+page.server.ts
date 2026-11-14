import { error, fail, redirect } from '@sveltejs/kit';
import { desdeCampos } from '$lib/formato';
import type { Actions, PageServerLoad } from './$types';

const ESTADOS = ['anunciada', 'realizada'];

// /nucleo/utopias/nueva crea; /nucleo/utopias/8 edita la N°08.
async function buscar(sb: App.Locals['supabase'], param: string) {
	if (param === 'nueva') return null;
	const numero = Number(param);
	if (!Number.isInteger(numero) || numero < 1) error(404, 'No existe esa utopía.');
	const { data } = await sb.from('utopias').select('id, numero, fecha, estado').eq('numero', numero).maybeSingle();
	if (!data) error(404, 'No existe esa utopía.');
	return data as { id: number; numero: number; fecha: string; estado: string };
}

export const load: PageServerLoad = async ({ params, locals }) => {
	const sb = locals.supabase;
	const u = await buscar(sb, params.numero);
	if (!u) {
		const { data } = await sb.from('utopias').select('numero').order('numero', { ascending: false }).limit(1).maybeSingle();
		return { u: null, lugar: '', confirmados: null, siguiente: ((data?.numero as number | undefined) ?? 0) + 1 };
	}
	const [lugar, confirmados] = await Promise.all([
		sb.from('utopia_lugar').select('lugar').eq('utopia_id', u.id).maybeSingle(),
		sb.rpc('confirmados', { p_utopia: u.id })
	]);
	return { u, lugar: (lugar.data?.lugar as string | undefined) ?? '', confirmados: (confirmados.data as number | null) ?? 0, siguiente: null };
};

export const actions: Actions = {
	guardar: async ({ request, params, locals }) => {
		const u = await buscar(locals.supabase, params.numero);
		const f = await request.formData();
		const numero = Number(f.get('numero'));
		const dia = String(f.get('fecha') ?? '');
		const hora = String(f.get('hora') ?? '');
		const estado = u ? String(f.get('estado') ?? '') : 'anunciada';
		const lugar = String(f.get('lugar') ?? '').trim();
		const valores = { numero: String(f.get('numero') ?? ''), fecha: dia, hora, estado, lugar };

		if (!Number.isInteger(numero) || numero < 1 || numero > 999) return fail(400, { ...valores, error: 'El número tiene que ser entero, entre 1 y 999.' });
		const iso = desdeCampos(dia, hora);
		if (!iso) return fail(400, { ...valores, error: 'La fecha o la hora no son válidas.' });
		if (!ESTADOS.includes(estado)) return fail(400, { ...valores, error: 'Elegí un estado.' });
		if (lugar.length > 500) return fail(400, { ...valores, error: 'El lugar supera los 500 caracteres.' });

		const { error: e } = await locals.supabase.rpc('guardar_utopia', {
			p_id: u?.id ?? null, p_numero: numero, p_fecha: iso, p_estado: estado, p_lugar: lugar
		});
		if (e?.code === '23505') return fail(409, { ...valores, error: `Ya existe la utopía N°${String(numero).padStart(2, '0')}.` });
		if (e) return fail(403, { ...valores, error: 'No se pudo guardar.' });
		redirect(303, '/nucleo');
	},

	eliminar: async ({ params, locals }) => {
		const u = await buscar(locals.supabase, params.numero);
		if (!u) return fail(400);
		// La política solo deja borrar utopías anunciadas sin actas ni presentaciones. Si no borra, no hay error: hay 0 filas.
		const { data, error: e } = await locals.supabase.from('utopias').delete().eq('id', u.id).select('id');
		if (e || !data?.length) return fail(409, { error: 'No se puede eliminar: tiene que estar anunciada y sin actas ni presentaciones.' });
		redirect(303, '/nucleo');
	}
};
