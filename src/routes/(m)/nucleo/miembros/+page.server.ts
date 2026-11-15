import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export type MiembroNucleo = { id: string; alias: string; estado: string; creado: string; titulos: string[]; utopico: boolean; testigo: boolean };
export type Titulo = { id: string; nombre: string; tipo: 'derivado' | 'asignado' | 'cargo' };

export const load: PageServerLoad = async ({ locals }) => {
	const sb = locals.supabase;
	const [miembros, admision, titulos, bitacora] = await Promise.all([
		sb.rpc('nucleo_miembros'),
		sb.rpc('nucleo_admision'),
		sb.from('titulos').select('id, nombre, tipo').order('tipo').order('nombre'),
		sb.from('nucleo_bitacora').select('id, accion, objetivo, momento, actor:miembros(alias)').order('momento', { ascending: false }).limit(20)
	]);
	return {
		miembros: (miembros.data ?? []) as MiembroNucleo[],
		admision: (admision.data ?? []) as { email: string; alias: string; agregado: string }[],
		titulos: (titulos.data ?? []) as Titulo[],
		bitacora: (bitacora.data ?? []) as unknown as { id: number; accion: string; objetivo: string; momento: string; actor: { alias: string } | null }[]
	};
};

export const actions: Actions = {
	admitir: async ({ request, locals }) => {
		const lista = String((await request.formData()).get('lista') ?? '');
		if (!lista.trim()) return fail(400, { admision: 'Pegá al menos un mail.', lista });
		if (lista.length > 50000) return fail(400, { admision: 'La lista es demasiado larga: dividila.', lista });
		const { data, error } = await locals.supabase.rpc('admitir', { p_lista: lista });
		if (error) return fail(400, { admision: error.message.includes('500') ? 'Más de 500 mails nuevos: dividí la lista.' : 'No se pudo admitir.', lista });
		return { admitidos: (data ?? []) as { email: string; alias: string }[] };
	},

	quitar: async ({ request, locals }) => {
		const email = String((await request.formData()).get('email') ?? '');
		const { error } = await locals.supabase.rpc('quitar_admision', { p_email: email });
		if (error) return fail(400, { quitar: error.message.includes('ya es miembro') ? 'Ya entró: es miembro.' : 'No se pudo quitar.' });
	}
};
