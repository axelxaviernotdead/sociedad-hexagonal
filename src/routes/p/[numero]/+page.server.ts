import { error, fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

type Presentacion = {
	numero: number; titulo: string; resumen: string | null; duracion_s: number | null; temas: string[];
	visibilidad: 'miembros' | 'publico'; capitulos: { t: number; titulo: string }[];
	audio_path: string | null; video_path: string | null; diapositivas_path: string | null;
	alias: string | null; utopia: number; fecha: string; es_mia: boolean | null;
};

export const load: PageServerLoad = async ({ params, locals }) => {
	const n = Number(params.numero);
	if (!Number.isInteger(n) || n < 1) error(404, 'No existe esa presentación.');
	const { data } = await locals.supabase.rpc('presentacion', { n });
	const p = data as Presentacion | null;
	if (!p) error(404, 'No existe esa presentación o no tenés acceso.');

	// URLs firmadas: vencen a las 3 h. La política del bucket repite el control de visibilidad.
	const firmar = async (ruta: string | null) => {
		if (!ruta) return null;
		const { data } = await locals.supabase.storage.from('archivo').createSignedUrl(ruta, 60 * 60 * 3);
		return data?.signedUrl ?? null;
	};
	const [audio, video, diapositivas] = await Promise.all([firmar(p.audio_path), firmar(p.video_path), firmar(p.diapositivas_path)]);

	const { audio_path, video_path, diapositivas_path, ...resto } = p;
	return { p: resto, urls: { audio, video, diapositivas } };
};

export const actions: Actions = {
	visibilidad: async ({ request, params, locals }) => {
		const v = String((await request.formData()).get('visibilidad'));
		if (!['miembros', 'publico'].includes(v)) return fail(400);
		// La política de la tabla solo permite el cambio al autor.
		const { error: e } = await locals.supabase.from('presentaciones').update({ visibilidad: v }).eq('numero', Number(params.numero));
		if (e) return fail(403, { error: 'Solo quien presentó puede cambiar la visibilidad.' });
	}
};
