import { error } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';

// Comodidad, no barrera: aunque esto fallara, la base rechaza los cambios de quien no es núcleo.
export const load: LayoutServerLoad = async ({ parent }) => {
	const { nucleo } = await parent();
	if (!nucleo) error(404, 'No existe esa página.');
};
