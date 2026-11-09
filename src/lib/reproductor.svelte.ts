export type Pista = { numero: number; titulo: string; alias: string | null; url: string };

class Reproductor {
	pista = $state<Pista | null>(null);
	sonando = $state(false);
	tiempo = $state(0);
	total = $state(0);
	pedido = $state<number | null>(null);

	cargar(p: Pista, desde: number | null = null) {
		if (this.pista?.numero !== p.numero) this.pista = p;
		this.pedido = desde;
		this.sonando = true;
	}
	cerrar() {
		this.pista = null;
		this.sonando = false;
	}
}

// Solo se modifica en el navegador, a partir de una acción del usuario.
export const reproductor = new Reproductor();
