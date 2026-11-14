import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const sb = locals.supabase;
	const [utopias, lugares, eventos] = await Promise.all([
		sb.from('utopias').select('id, numero, fecha, estado').order('numero', { ascending: false }),
		sb.from('utopia_lugar').select('utopia_id'),
		sb.from('eventos').select('id, fecha, titulo, detalle, utopia_id').gte('fecha', new Date().toISOString()).order('fecha')
	]);
	const conLugar = new Set((lugares.data ?? []).map((l) => l.utopia_id as number));
	const lista = utopias.data ?? [];

	// Confirmados solo de las anunciadas: suelen ser una o dos.
	const confirmados = new Map<number, number>();
	await Promise.all(
		lista.filter((u) => u.estado === 'anunciada').map(async (u) => {
			const { data } = await sb.rpc('confirmados', { p_utopia: u.id });
			confirmados.set(u.id, (data as number | null) ?? 0);
		})
	);

	return {
		utopias: lista.map((u) => ({ ...u, lugar: conLugar.has(u.id), confirmados: confirmados.get(u.id) ?? null })),
		eventos: eventos.data ?? []
	};
};
