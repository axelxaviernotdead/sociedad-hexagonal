import { error, fail, redirect } from '@sveltejs/kit';
import { desdeCampos } from '$lib/formato';
import type { Actions, PageServerLoad } from './$types';

type Evento = { id: number; fecha: string; titulo: string; detalle: string | null; utopia_id: number | null };

// /nucleo/eventos/nuevo crea; /nucleo/eventos/12 edita.
// El evento de una utopía (utopia_id) toma la fecha de la utopía: acá solo se editan título y detalle.
async function buscar(sb: App.Locals['supabase'], param: string) {
	if (param === 'nuevo') return null;
	const id = Number(param);
	if (!Number.isInteger(id) || id < 1) error(404, 'No existe ese evento.');
	const { data } = await sb.from('eventos').select('id, fecha, titulo, detalle, utopia_id').eq('id', id).maybeSingle();
	if (!data) error(404, 'No existe ese evento.');
	return data as Evento;
}

export const load: PageServerLoad = async ({ params, locals }) => {
	const e = await buscar(locals.supabase, params.id);
	let utopia: number | null = null;
	if (e?.utopia_id) {
		const { data } = await locals.supabase.from('utopias').select('numero').eq('id', e.utopia_id).maybeSingle();
		utopia = (data?.numero as number | undefined) ?? null;
	}
	return { e, utopia };
};

export const actions: Actions = {
	guardar: async ({ request, params, locals }) => {
		const e = await buscar(locals.supabase, params.id);
		const f = await request.formData();
		const titulo = String(f.get('titulo') ?? '').trim();
		const detalle = String(f.get('detalle') ?? '').trim();
		const dia = String(f.get('fecha') ?? '');
		const hora = String(f.get('hora') ?? '');
		const valores = { titulo, detalle, fecha: dia, hora };

		if (titulo.length < 1 || titulo.length > 160) return fail(400, { ...valores, error: 'El título tiene que tener entre 1 y 160 caracteres.' });
		if (detalle.length > 300) return fail(400, { ...valores, error: 'El detalle supera los 300 caracteres.' });

		const cambios: Record<string, string | null> = { titulo, detalle: detalle || null };
		if (!e?.utopia_id) {
			const iso = desdeCampos(dia, hora);
			if (!iso) return fail(400, { ...valores, error: 'La fecha o la hora no son válidas.' });
			cambios.fecha = iso;
		}

		const q = e
			? locals.supabase.from('eventos').update(cambios).eq('id', e.id).select('id')
			: locals.supabase.from('eventos').insert(cambios).select('id');
		const { data, error: err } = await q;
		if (err || !data?.length) return fail(403, { ...valores, error: 'No se pudo guardar.' });
		redirect(303, '/nucleo');
	},

	eliminar: async ({ params, locals }) => {
		const e = await buscar(locals.supabase, params.id);
		if (!e || e.utopia_id) return fail(400, { error: 'El evento de una utopía se elimina con la utopía.' });
		const { data, error: err } = await locals.supabase.from('eventos').delete().eq('id', e.id).select('id');
		if (err || !data?.length) return fail(403, { error: 'No se pudo eliminar.' });
		redirect(303, '/nucleo');
	}
};
