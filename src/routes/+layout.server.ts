import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ locals }) => {
	const user = await locals.getUser();
	if (!user) return { alias: null as string | null };
	const { data } = await locals.supabase.from('miembros').select('alias').eq('id', user.id).maybeSingle();
	return { alias: (data?.alias as string | undefined) ?? null };
};
