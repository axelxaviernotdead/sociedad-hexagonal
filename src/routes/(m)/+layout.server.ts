import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ parent }) => {
	const { alias } = await parent();
	if (!alias) redirect(303, '/entrar');
};
