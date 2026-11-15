import { error, fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import type { MiembroNucleo, Titulo } from '../+page.server';

const MENSAJES: Record<string, string> = {
	'no podés sacarte el cargo de núcleo': 'No podés sacarte tu propio cargo de núcleo.',
	'no podés cambiar tu propio estado': 'No podés expulsarte.',
	'ese título no se asigna': 'Ese título no se asigna: se calcula solo.'
};
const mensaje = (e: { message: string }) => MENSAJES[e.message] ?? 'No se pudo hacer el cambio.';

export const load: PageServerLoad = async ({ params, locals }) => {
	const [user, miembros, titulos] = await Promise.all([
		locals.getUser(),
		locals.supabase.rpc('nucleo_miembros'),
		locals.supabase.from('titulos').select('id, nombre, tipo').order('tipo').order('nombre')
	]);
	const m = ((miembros.data ?? []) as MiembroNucleo[]).find((x) => x.id === params.id);
	if (!m) error(404, 'No existe ese miembro.');
	return { m, titulos: (titulos.data ?? []) as Titulo[], soyYo: user?.id === m.id };
};

export const actions: Actions = {
	dar: async ({ request, params, locals }) => {
		const titulo = String((await request.formData()).get('titulo') ?? '');
		const { error: e } = await locals.supabase.rpc('dar_titulo', { p_miembro: params.id, p_titulo: titulo });
		if (e) return fail(400, { error: mensaje(e) });
	},
	sacar: async ({ request, params, locals }) => {
		const titulo = String((await request.formData()).get('titulo') ?? '');
		const { error: e } = await locals.supabase.rpc('sacar_titulo', { p_miembro: params.id, p_titulo: titulo });
		if (e) return fail(400, { error: mensaje(e) });
	},
	estado: async ({ request, params, locals }) => {
		const estado = String((await request.formData()).get('estado') ?? '');
		const { error: e } = await locals.supabase.rpc('cambiar_estado', { p_miembro: params.id, p_estado: estado });
		if (e) return fail(400, { error: mensaje(e) });
	}
};
