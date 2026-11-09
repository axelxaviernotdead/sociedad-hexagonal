import { fail, redirect } from '@sveltejs/kit';
import { TEMAS } from '$lib/temas';
import type { Actions } from './$types';

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const f = await request.formData();
		const titulo = String(f.get('titulo') ?? '').trim();
		const tema = String(f.get('tema') ?? '');
		const cuerpo = String(f.get('cuerpo') ?? '').trim();
		const valores = { titulo, tema, cuerpo };
		if (titulo.length < 3 || titulo.length > 160) return fail(400, { ...valores, error: 'El título tiene que tener entre 3 y 160 caracteres.' });
		if (!(TEMAS as readonly string[]).includes(tema)) return fail(400, { ...valores, error: 'Elegí un tema.' });
		if (!cuerpo) return fail(400, { ...valores, error: 'El primer mensaje no puede estar vacío.' });
		const { data, error } = await locals.supabase.rpc('abrir_hilo', { p_titulo: titulo, p_tema: tema, p_cuerpo: cuerpo });
		if (error) return fail(500, { ...valores, error: 'No se pudo abrir el hilo.' });
		redirect(303, `/foro/${data}`);
	}
};
