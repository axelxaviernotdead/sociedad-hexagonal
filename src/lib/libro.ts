// Libro de visitas: excepción explícita a DESIGN.md (fuentes y colores propios).
// Las claves son las mismas que acepta la base (check de libro_notas): nunca se guarda CSS.
// Solo fuentes del sistema: la CSP no permite cargar fuentes de afuera.
export const FUENTES = {
	sitio: "'Helvetica Neue', Helvetica, Arial, sans-serif",
	serif: "Georgia, 'Times New Roman', Times, serif",
	mono: "ui-monospace, Menlo, Consolas, 'Courier New', monospace",
	manuscrita: "'Bradley Hand', 'Segoe Print', 'Comic Sans MS', cursive",
	redonda: "ui-rounded, 'Arial Rounded MT Bold', 'Trebuchet MS', sans-serif",
	angosta: "'Arial Narrow', 'Helvetica Neue Condensed', 'Roboto Condensed', sans-serif"
} as const;

export const COLORES = {
	negro: '#000000',
	gris: '#8f8f8f',
	rojo: '#c8102e',
	azul: '#1f4fd1',
	verde: '#1b7f3b',
	naranja: '#d35400',
	violeta: '#7a2fbf',
	rosa: '#c2185b'
} as const;

export type Fuente = keyof typeof FUENTES;
export type Color = keyof typeof COLORES;
export const esFuente = (v: unknown): v is Fuente => typeof v === 'string' && v in FUENTES;
export const esColor = (v: unknown): v is Color => typeof v === 'string' && v in COLORES;

export type Nota = {
	id: number; texto: string; x: number; y: number; fuente: Fuente; color: Color;
	autor_id: string; autor: { alias: string } | null;
};
