import { TEMAS } from '$lib/temas';
import type { PageServerLoad } from './$types';

const ORDENES = { actividad: 'actividad', nuevos: 'creado', respuestas: 'respuestas' } as const;
const POR_PAGINA = 40;

export const load: PageServerLoad = async ({ locals, url }) => {
	const tema = url.searchParams.get('tema');
	const orden = (url.searchParams.get('orden') ?? 'actividad') as keyof typeof ORDENES;
	const pagina = Math.max(1, Number(url.searchParams.get('p')) || 1);

	let q = locals.supabase
		.from('hilos')
		.select('id, titulo, tema, respuestas, actividad, autor:miembros(alias)', { count: 'exact' })
		.order(ORDENES[orden] ?? 'actividad', { ascending: false })
		.range((pagina - 1) * POR_PAGINA, pagina * POR_PAGINA - 1);
	if (tema && (TEMAS as readonly string[]).includes(tema)) q = q.eq('tema', tema);

	const { data, count } = await q;
	return {
		hilos: (data ?? []) as unknown as { id: number; titulo: string; tema: string; respuestas: number; actividad: string; autor: { alias: string } | null }[],
		tema: tema ?? null,
		orden: ORDENES[orden] ? orden : 'actividad',
		pagina,
		hayMas: (count ?? 0) > pagina * POR_PAGINA,
		desde: (pagina - 1) * POR_PAGINA
	};
};
