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
