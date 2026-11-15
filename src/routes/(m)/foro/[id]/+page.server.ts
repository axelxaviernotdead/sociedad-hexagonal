import { error, fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const id = Number(params.id);
	if (!Number.isInteger(id)) error(404, 'No existe ese hilo.');
	const [hilo, mensajes] = await Promise.all([
		locals.supabase.from('hilos').select('id, titulo, creado, respuestas, autor:miembros(alias)').eq('id', id).maybeSingle(),
		locals.supabase.from('mensajes').select('numero, cuerpo, creado, autor:miembros(alias)').eq('hilo_id', id).order('numero')
	]);
	if (!hilo.data) error(404, 'No existe ese hilo.');
	return {
		hilo: hilo.data as unknown as { id: number; titulo: string; creado: string; respuestas: number; autor: { alias: string } | null },
		mensajes: (mensajes.data ?? []) as unknown as { numero: number; cuerpo: string; creado: string; autor: { alias: string } | null }[]
	};
};

export const actions: Actions = {
	default: async ({ request, params, locals }) => {
		const cuerpo = String((await request.formData()).get('cuerpo') ?? '').trim();
		if (!cuerpo) return fail(400, { error: 'El mensaje está vacío.', cuerpo });
		if (cuerpo.length > 20000) return fail(400, { error: 'El mensaje supera los 20.000 caracteres.', cuerpo });
		const { error: e } = await locals.supabase.from('mensajes').insert({ hilo_id: Number(params.id), cuerpo, numero: 0 });
		if (e) return fail(500, { error: 'No se pudo publicar.', cuerpo });
		return { publicado: true };
	}
};
