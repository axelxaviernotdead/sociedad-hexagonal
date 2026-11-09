// Divide un mensaje en texto y citas (>>número) sin interpretar HTML.
export type Parte = { tipo: 'texto'; valor: string } | { tipo: 'cita'; numero: number };

export function partes(texto: string): Parte[] {
	const salida: Parte[] = [];
	const re = />>(\d{1,5})/g;
	let ultimo = 0;
	for (const m of texto.matchAll(re)) {
		if (m.index! > ultimo) salida.push({ tipo: 'texto', valor: texto.slice(ultimo, m.index) });
		salida.push({ tipo: 'cita', numero: Number(m[1]) });
		ultimo = m.index! + m[0].length;
	}
	if (ultimo < texto.length) salida.push({ tipo: 'texto', valor: texto.slice(ultimo) });
	return salida;
}
