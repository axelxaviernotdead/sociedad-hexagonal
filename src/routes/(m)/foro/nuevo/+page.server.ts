import { fail, redirect } from '@sveltejs/kit';
import type { Actions } from './$types';

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const f = await request.formData();
		const titulo = String(f.get('titulo') ?? '').trim();
		const cuerpo = String(f.get('cuerpo') ?? '').trim();
		const valores = { titulo, cuerpo };
		if (titulo.length < 3 || titulo.length > 160) return fail(400, { ...valores, error: 'El título tiene que tener entre 3 y 160 caracteres.' });
		if (!cuerpo) return fail(400, { ...valores, error: 'El primer mensaje no puede estar vacío.' });
		let { data, error } = await locals.supabase.rpc('abrir_hilo', { p_titulo: titulo, p_cuerpo: cuerpo });
		// Mientras no se corra la migración 0005, la base solo tiene la versión con tema (obligatorio).
		if (error?.code === 'PGRST202') ({ data, error } = await locals.supabase.rpc('abrir_hilo', { p_titulo: titulo, p_tema: 'general', p_cuerpo: cuerpo }));
		if (error) return fail(500, { ...valores, error: 'No se pudo abrir el hilo.' });
		redirect(303, `/foro/${data}`);
	}
};
