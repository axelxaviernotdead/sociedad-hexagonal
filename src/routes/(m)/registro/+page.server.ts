import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

type Registro = {
	alias: string; email: string; creado: string; titulos: string[];
	asistencia: { numero: number; presente: boolean }[];
	presentaciones: { numero: number; titulo: string; utopia: number; visibilidad: string }[];
};

export const load: PageServerLoad = async ({ locals }) => {
	const { data } = await locals.supabase.rpc('mi_registro');
	return { r: data as Registro };
};

export const actions: Actions = {
	alias: async ({ request, locals }) => {
		const alias = String((await request.formData()).get('alias') ?? '').trim();
		if (!/^[\p{L}\p{N}._-]{2,32}$/u.test(alias)) return fail(400, { error: 'Entre 2 y 32 caracteres: letras, números, punto, guion o guion bajo.', alias });
		const user = await locals.getUser();
		if (!user) return fail(401);
		const { error } = await locals.supabase.from('miembros').update({ alias }).eq('id', user.id);
		if (error) return fail(409, { error: error.code === '23505' ? 'Ese alias ya está en uso.' : 'No se pudo cambiar el alias.', alias });
		return { ok: true };
	}
};
