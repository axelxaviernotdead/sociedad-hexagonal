import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ locals }) => {
	const user = await locals.getUser();
	if (!user) return { alias: null as string | null, nucleo: false };
	const [miembro, nucleo] = await Promise.all([
		locals.supabase.from('miembros').select('alias').eq('id', user.id).maybeSingle(),
		locals.supabase.rpc('es_nucleo')
	]);
	// nucleo solo decide si se muestra el enlace; los permisos los controla la base.
	return { alias: (miembro.data?.alias as string | undefined) ?? null, nucleo: nucleo.data === true };
};
