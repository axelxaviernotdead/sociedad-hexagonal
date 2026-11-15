import { fail } from '@sveltejs/kit';
import { mes } from '$lib/formato';
import { esColor, esFuente, type Nota } from '$lib/libro';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const sb = locals.supabase;
	const ahora = new Date().toISOString();
	const m = mes();

	const [user, delMes, siguiente, proxima, hilos, notas] = await Promise.all([
		locals.getUser(),
		sb.from('eventos').select('id, fecha, titulo, utopia_id').gte('fecha', m.desde).lt('fecha', m.hasta).order('fecha'),
		sb.from('eventos').select('id, fecha, titulo, detalle, utopia_id').gte('fecha', ahora).order('fecha').limit(1).maybeSingle(),
		sb.from('utopias').select('id, numero, fecha').eq('estado', 'anunciada').gte('fecha', ahora).order('fecha').limit(1).maybeSingle(),
		sb.from('hilos').select('id, titulo, respuestas, actividad').order('actividad', { ascending: false }).limit(5),
		// La última nota tocada va al final: se dibuja arriba de las demás.
		sb.from('libro_notas').select('id, texto, x, y, fuente, color, autor_id, autor:miembros(alias)').order('movido')
	]);

	let utopia = null;
	if (proxima.data) {
		const u = proxima.data;
		const [mia, confirmados, lugar] = await Promise.all([
			sb.from('asistencias').select('estado').eq('utopia_id', u.id).maybeSingle(),
			sb.rpc('confirmados', { p_utopia: u.id }),
			sb.from('utopia_lugar').select('lugar').eq('utopia_id', u.id).maybeSingle()
		]);
		utopia = { ...u, estado: (mia.data?.estado as string | undefined) ?? null, confirmados: (confirmados.data as number) ?? 0, lugar: lugar.data?.lugar ?? null };
	}

	return {
		mes: m,
		delMes: delMes.data ?? [],
		siguiente: siguiente.data as { id: number; fecha: string; titulo: string; detalle: string | null; utopia_id: number | null } | null,
		utopia,
		hilos: hilos.data ?? [],
		notas: (notas.data ?? []) as unknown as Nota[],
		yo: user?.id ?? null
	};
};

export const actions: Actions = {
	asistencia: async ({ request, locals }) => {
		const f = await request.formData();
		const utopia_id = Number(f.get('utopia_id'));
		const estado = String(f.get('estado'));
		if (!Number.isInteger(utopia_id) || !['asistire', 'no_asistire'].includes(estado)) return fail(400);
		const user = await locals.getUser();
		if (!user) return fail(401);
		const { error } = await locals.supabase
			.from('asistencias')
			.upsert({ utopia_id, miembro_id: user.id, estado, actualizado: new Date().toISOString() });
		if (error) return fail(500, { error: 'No se pudo guardar la asistencia.' });
	},

	// Libro de visitas. Las políticas de libro_notas deciden qué nota puede tocar cada quien;
	// si no corresponde, la base no cambia ninguna fila.
	escribir: async ({ request, locals }) => {
		const f = await request.formData();
		const texto = String(f.get('texto') ?? '').trim();
		const fuente = f.get('fuente');
		const color = f.get('color');
		if (!texto) return fail(400, { libro: 'La nota está vacía.', texto });
		if (texto.length > 280) return fail(400, { libro: 'La nota supera los 280 caracteres.', texto });
		if (!esFuente(fuente) || !esColor(color)) return fail(400, { libro: 'Elegí fuente y color.', texto });
		// Aparece en un lugar al azar, cerca del centro; después se mueve.
		const x = 0.2 + Math.random() * 0.6;
		const y = 0.2 + Math.random() * 0.6;
		const { error } = await locals.supabase.from('libro_notas').insert({ texto, fuente, color, x, y });
		if (error) return fail(403, { libro: 'No se pudo dejar la nota. Cada miembro puede tener hasta 20.', texto });
		return { escrita: true };
	},

	mover: async ({ request, locals }) => {
		const f = await request.formData();
		const id = Number(f.get('id'));
		const x = Number(f.get('x'));
		const y = Number(f.get('y'));
		if (!Number.isInteger(id) || !(x >= 0 && x <= 1) || !(y >= 0 && y <= 1)) return fail(400);
		const { data } = await locals.supabase.from('libro_notas').update({ x, y }).eq('id', id).select('id');
		if (!data?.length) return fail(403);
	},

	cambiar: async ({ request, locals }) => {
		const f = await request.formData();
		const id = Number(f.get('id'));
		const cambios: Record<string, string> = {};
		const fuente = f.get('fuente');
		const color = f.get('color');
		if (fuente !== null) { if (!esFuente(fuente)) return fail(400); cambios.fuente = fuente; }
		if (color !== null) { if (!esColor(color)) return fail(400); cambios.color = color; }
		if (!Number.isInteger(id) || !Object.keys(cambios).length) return fail(400);
		const { data } = await locals.supabase.from('libro_notas').update(cambios).eq('id', id).select('id');
		if (!data?.length) return fail(403, { libro: 'Solo podés cambiar tus notas.' });
	},

	borrar: async ({ request, locals }) => {
		const id = Number((await request.formData()).get('id'));
		if (!Number.isInteger(id)) return fail(400);
		const { data } = await locals.supabase.from('libro_notas').delete().eq('id', id).select('id');
		if (!data?.length) return fail(403, { libro: 'No se pudo borrar la nota.' });
	}
};
