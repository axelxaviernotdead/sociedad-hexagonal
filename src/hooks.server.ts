import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import type { Handle } from '@sveltejs/kit';

const PRIVADAS = ['/inicio', '/archivo', '/foro', '/registro', '/nucleo', '/entrar'];
const SIN_CACHE = [...PRIVADAS, '/p/'];

export const handle: Handle = async ({ event, resolve }) => {
	event.locals.supabase = createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
		cookies: {
			getAll: () => event.cookies.getAll(),
			setAll: (lista: { name: string; value: string; options: CookieOptions }[]) =>
				lista.forEach(({ name, value, options }) =>
					event.cookies.set(name, value, { ...options, path: '/', httpOnly: true, sameSite: 'lax', secure: true })
				)
		}
	});

	// getUser valida el token contra Supabase; no confiar en getSession del lado servidor.
	event.locals.getUser = async () => {
		const { data, error } = await event.locals.supabase.auth.getUser();
		return error ? null : data.user;
	};

	const respuesta = await resolve(event, {
		filterSerializedResponseHeaders: (nombre) => nombre === 'content-range' || nombre === 'x-supabase-api-version'
	});

	respuesta.headers.set('X-Content-Type-Options', 'nosniff');
	respuesta.headers.set('Referrer-Policy', 'same-origin');
	respuesta.headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=(), interest-cohort=()');
	respuesta.headers.set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload');
	const ruta = event.url.pathname;
	if (PRIVADAS.some((p) => ruta.startsWith(p))) respuesta.headers.set('X-Robots-Tag', 'noindex, nofollow, noarchive');
	if (SIN_CACHE.some((p) => ruta.startsWith(p))) respuesta.headers.set('Cache-Control', 'private, no-store');
	return respuesta;
};
