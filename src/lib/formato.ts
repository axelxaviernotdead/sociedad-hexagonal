const zona = 'America/Argentina/Buenos_Aires';

export function duracion(s: number | null | undefined): string {
	if (s == null) return '';
	const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), x = Math.floor(s % 60);
	return [h, m, x].map((n) => String(n).padStart(2, '0')).join(':');
}

export function fecha(iso: string): string {
	const d = new Date(iso);
	const p = new Intl.DateTimeFormat('es-AR', { timeZone: zona, day: '2-digit', month: '2-digit', year: 'numeric' }).formatToParts(d);
	const v = (t: string) => p.find((x) => x.type === t)?.value;
	return `${v('day')}.${v('month')}.${v('year')}`;
}

export function dia(iso: string): string {
	return new Intl.DateTimeFormat('es-AR', { timeZone: zona, weekday: 'short' }).format(new Date(iso)).replace('.', '');
}

export function hora(iso: string): string {
	const s = new Intl.DateTimeFormat('es-AR', { timeZone: zona, hour: '2-digit', minute: '2-digit', hour12: false }).format(new Date(iso));
	return s === '00:00' ? '' : s;
}

export function hace(iso: string): string {
	const min = Math.max(0, Math.round((Date.now() - new Date(iso).getTime()) / 60000));
	if (min < 60) return `${min} min`;
	const h = Math.round(min / 60);
	if (h < 24) return `${h} h`;
	return `${Math.round(h / 24)} d`;
}

export const n3 = (n: number) => String(n).padStart(3, '0');
export const n2 = (n: number) => String(n).padStart(2, '0');

// Campos de formulario (<input type="date"> y <input type="time">), en hora de Buenos Aires.
export function fechaCampo(iso: string): string {
	const p = new Intl.DateTimeFormat('en-CA', { timeZone: zona, year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date(iso));
	const v = (t: string) => p.find((x) => x.type === t)?.value;
	return `${v('year')}-${v('month')}-${v('day')}`;
}

// Sin hora se guarda 00:00, que hora() muestra vacío.
export const horaCampo = hora;

// De los campos a ISO. Argentina no tiene horario de verano desde 2009: UTC−3 fijo.
// Devuelve null si la fecha o la hora no son válidas.
export function desdeCampos(f: string, h: string): string | null {
	if (!/^\d{4}-\d{2}-\d{2}$/.test(f) || (h !== '' && !/^\d{2}:\d{2}$/.test(h))) return null;
	const d = new Date(`${f}T${h || '00:00'}:00-03:00`);
	return Number.isNaN(d.getTime()) || fechaCampo(d.toISOString()) !== f ? null : d.toISOString();
}

// Mes que contiene `ahora`, en hora de Buenos Aires (UTC−3 fijo).
// semanaInicio: posición del día 1 en una semana que empieza el lunes (0 = lunes).
export function mes(ahora: Date = new Date()) {
	const [anio, numero] = fechaCampo(ahora.toISOString()).split('-').map(Number);
	const dias = new Date(Date.UTC(anio, numero, 0)).getUTCDate();
	const semanaInicio = (new Date(Date.UTC(anio, numero - 1, 1)).getUTCDay() + 6) % 7;
	const nombre = new Intl.DateTimeFormat('es-AR', { month: 'long', timeZone: 'UTC' }).format(new Date(Date.UTC(anio, numero - 1, 1)));
	const sig = numero === 12 ? [anio + 1, 1] : [anio, numero + 1];
	return {
		anio, numero, dias, semanaInicio, nombre,
		desde: new Date(`${anio}-${n2(numero)}-01T00:00:00-03:00`).toISOString(),
		hasta: new Date(`${sig[0]}-${n2(sig[1])}-01T00:00:00-03:00`).toISOString()
	};
}

// Día del mes (1–31) de una fecha, en hora de Buenos Aires.
export const diaDelMes = (iso: string) => Number(fechaCampo(iso).slice(8));
