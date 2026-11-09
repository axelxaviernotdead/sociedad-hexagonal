import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ parent }) => {
	const { alias } = await parent();
	if (alias) redirect(303, '/inicio');
};

export const actions: Actions = {
	default: async ({ request, locals, url }) => {
		const email = String((await request.formData()).get('email') ?? '').trim().toLowerCase();
		if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return fail(400, { error: 'El mail no es válido.', email });
		// La respuesta es la misma figure o no en la lista: no se revela quién es miembro.
		await locals.supabase.auth.signInWithOtp({
			email,
			options: { shouldCreateUser: true, emailRedirectTo: `${url.origin}/auth/confirm` }
		});
		return { enviado: true };
	}
};
