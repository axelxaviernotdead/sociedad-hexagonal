import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, parent }) => {
	const { alias } = await parent();
	if (alias) redirect(303, '/inicio');
	const [archivo, datos] = await Promise.all([locals.supabase.rpc('archivo'), locals.supabase.rpc('datos_publicos')]);
	return { archivo: archivo.data ?? [], datos: datos.data as { primera: string | null; realizadas: number; publicas: number; total: number } | null };
};
