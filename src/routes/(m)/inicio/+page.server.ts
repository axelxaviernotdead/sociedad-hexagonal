import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const sb = locals.supabase;
	const ahora = new Date().toISOString();

	const [eventos, proxima, archivo] = await Promise.all([
		sb.from('eventos').select('id, fecha, titulo, detalle, utopia_id').gte('fecha', ahora).order('fecha').limit(12),
		sb.from('utopias').select('id, numero, fecha').eq('estado', 'anunciada').gte('fecha', ahora).order('fecha').limit(1).maybeSingle(),
		sb.rpc('archivo')
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

	return { eventos: eventos.data ?? [], utopia, archivo: archivo.data ?? [] };
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
	}
};
