<script lang="ts">
	// Libro de visitas: excepción explícita a DESIGN.md (ver src/lib/libro.ts).
	// Posición guardada como fracción del tablero: left = x · (ancho − ancho de nota), top = y · (alto − 3 líneas).
	import { enhance, deserialize } from '$app/forms';
	import { FUENTES, COLORES, type Nota, type Fuente, type Color } from '$lib/libro';

	let { notas, yo, nucleo, error = null, texto = '' }: {
		notas: Nota[]; yo: string | null; nucleo: boolean; error?: string | null; texto?: string;
	} = $props();

	// Cambios locales encima de lo que viene del servidor: posición y orden de apilado.
	let pos = $state<Record<number, { x: number; y: number }>>({});
	let arriba = $state<Record<number, number>>({});
	let tope = 0;
	let sel = $state<number | null>(null);
	let aviso = $state<string | null>(null);
	let nuevaFuente = $state<Fuente>('sitio');
	let nuevoColor = $state<Color>('negro');
	let tablero: HTMLDivElement;

	const vista = $derived(notas.map((n, i) => ({ ...n, ...(pos[n.id] ?? {}), z: arriba[n.id] ? 1000 + arriba[n.id] : i + 1 })));
	const elegida = $derived(vista.find((n) => n.id === sel) ?? null);
	const mia = (n: Nota) => n.autor_id === yo;
	const tocable = (n: Nota) => mia(n) || nucleo;
	const limitar = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v));

	async function guardar(id: number) {
		const p = pos[id];
		if (!p) return;
		const fd = new FormData();
		fd.set('id', String(id));
		fd.set('x', p.x.toFixed(4));
		fd.set('y', p.y.toFixed(4));
		const r = await fetch('?/mover', { method: 'POST', body: fd, headers: { 'x-sveltekit-action': 'true' } });
		const res = deserialize(await r.text());
		aviso = res.type === 'success' ? null : 'No se pudo guardar la posición.';
	}

	// Arrastre con mouse, dedo o lápiz. Un toque sin movimiento selecciona la nota.
	let arrastre: { id: number; offX: number; offY: number; sx: number; sy: number; movio: boolean } | null = null;

	function bajar(e: PointerEvent, n: Nota) {
		if (!tocable(n)) return;
		const el = e.currentTarget as HTMLElement;
		const r = el.getBoundingClientRect();
		arrastre = { id: n.id, offX: e.clientX - r.left, offY: e.clientY - r.top, sx: e.clientX, sy: e.clientY, movio: false };
		if (mia(n)) el.setPointerCapture(e.pointerId);
	}

	function arrastrar(e: PointerEvent, n: Nota) {
		if (!arrastre || arrastre.id !== n.id || !mia(n)) return;
		if (Math.abs(e.clientX - arrastre.sx) + Math.abs(e.clientY - arrastre.sy) > 4) arrastre.movio = true;
		if (!arrastre.movio) return;
		const el = e.currentTarget as HTMLElement;
		const b = tablero.getBoundingClientRect();
		const linea = parseFloat(getComputedStyle(tablero).getPropertyValue('--linea')) || 22;
		const left = limitar(e.clientX - b.left - arrastre.offX, 0, b.width - el.offsetWidth);
		const top = limitar(e.clientY - b.top - arrastre.offY, 0, b.height - el.offsetHeight);
		pos[n.id] = { x: limitar(left / (b.width - el.offsetWidth), 0, 1), y: limitar(top / (b.height - linea * 3), 0, 1) };
		arriba[n.id] = ++tope;
	}

	function soltar(n: Nota) {
		if (!arrastre || arrastre.id !== n.id) return;
		if (arrastre.movio) guardar(n.id);
		else sel = sel === n.id ? null : n.id;
		arrastre = null;
	}

	// Teclado: Enter elige la nota; las flechas mueven la propia y guardan al soltar.
	let espera: ReturnType<typeof setTimeout>;
	function tecla(e: KeyboardEvent, n: Nota) {
		if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); sel = sel === n.id ? null : n.id; return; }
		const d = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] }[e.key];
		if (!d || !mia(n)) return;
		e.preventDefault();
		const actual = pos[n.id] ?? { x: n.x, y: n.y };
		pos[n.id] = { x: limitar(actual.x + d[0] * 0.02, 0, 1), y: limitar(actual.y + d[1] * 0.02, 0, 1) };
		arriba[n.id] = ++tope;
		clearTimeout(espera);
		espera = setTimeout(() => guardar(n.id), 400);
	}

	const tras = () => async ({ update }: { update: (o?: { reset?: boolean }) => Promise<void> }) => {
		await update({ reset: false });
	};
</script>

<div class="tablero" bind:this={tablero} aria-label="Libro de visitas">
	{#each vista as n (n.id)}
		{#snippet contenido()}
			<span class="texto" style="font-family: {FUENTES[n.fuente]}; color: {COLORES[n.color]};">{#if sel === n.id}▶ {/if}{n.texto}</span>
			<span class="g">{n.autor?.alias ?? ''}</span>
		{/snippet}
		{#if tocable(n)}
			<div
				class="nota"
				class:mia={mia(n)}
				style="--x: {n.x}; --y: {n.y}; z-index: {n.z};"
				role="button"
				tabindex="0"
				aria-pressed={sel === n.id}
				aria-label="Nota de {n.autor?.alias ?? 'un miembro'}"
				onpointerdown={(e) => bajar(e, n)}
				onpointermove={(e) => arrastrar(e, n)}
				onpointerup={() => soltar(n)}
				onpointercancel={() => (arrastre = null)}
				onkeydown={(e) => tecla(e, n)}
			>{@render contenido()}</div>
		{:else}
			<div class="nota" style="--x: {n.x}; --y: {n.y}; z-index: {n.z};">{@render contenido()}</div>
		{/if}
	{/each}
</div>

{#if aviso}<p class="e1">{aviso}</p>{/if}

{#if elegida && mia(elegida)}
	<table class="e1"><tbody>
		<tr>
			<td class="g">fuente</td>
			<td>
				<form method="POST" action="?/cambiar" use:enhance={tras} class="fila">
					<input type="hidden" name="id" value={elegida.id} />
					{#each Object.entries(FUENTES) as [k, familia]}
						<button class="opcion" name="fuente" value={k} style="font-family: {familia}; color: var({elegida.fuente === k ? '--negro' : '--gris'});">{elegida.fuente === k ? '▶ ' : ''}{k}</button>
					{/each}
				</form>
			</td>
		</tr>
		<tr>
			<td class="g">color</td>
			<td>
				<form method="POST" action="?/cambiar" use:enhance={tras} class="fila">
					<input type="hidden" name="id" value={elegida.id} />
					{#each Object.entries(COLORES) as [k, valor]}
						<button class="opcion" name="color" value={k} style="color: {valor};">{elegida.color === k ? '▶ ' : ''}{k}</button>
					{/each}
				</form>
			</td>
		</tr>
		<tr>
			<td></td>
			<td>
				<form method="POST" action="?/borrar" use:enhance class="fila">
					<input type="hidden" name="id" value={elegida.id} />
					<button onclick={() => (sel = null)}>borrar nota</button>
					<button type="button" class="opcion g" onclick={() => (sel = null)}>listo</button>
				</form>
			</td>
		</tr>
	</tbody></table>
{:else if elegida && nucleo}
	<form method="POST" action="?/borrar" use:enhance class="fila e1">
		<input type="hidden" name="id" value={elegida.id} />
		<span class="g">Nota de {elegida.autor?.alias ?? 'un miembro'}.</span>
		<button onclick={() => (sel = null)}>borrar nota</button>
		<button type="button" class="opcion g" onclick={() => (sel = null)}>listo</button>
	</form>
{/if}

<form method="POST" action="?/escribir" use:enhance class="e2">
	<label for="nota" class="oculto">Nota</label>
	<textarea id="nota" name="texto" maxlength="280" required placeholder="Texto plano. Hasta 280 caracteres.">{texto}</textarea>
	<input type="hidden" name="fuente" value={nuevaFuente} />
	<input type="hidden" name="color" value={nuevoColor} />
	<table class="medio"><tbody>
		<tr>
			<td class="g">fuente</td>
			<td class="fila">
				{#each Object.entries(FUENTES) as [k, familia]}
					<button type="button" class="opcion" aria-pressed={nuevaFuente === k} onclick={() => (nuevaFuente = k as Fuente)} style="font-family: {familia}; color: var({nuevaFuente === k ? '--negro' : '--gris'});">{nuevaFuente === k ? '▶ ' : ''}{k}</button>
				{/each}
			</td>
		</tr>
		<tr>
			<td class="g">color</td>
			<td class="fila">
				{#each Object.entries(COLORES) as [k, valor]}
					<button type="button" class="opcion" aria-pressed={nuevoColor === k} onclick={() => (nuevoColor = k as Color)} style="color: {valor};">{nuevoColor === k ? '▶ ' : ''}{k}</button>
				{/each}
			</td>
		</tr>
	</tbody></table>
	<p class="fila medio"><button>dejar nota</button><span class="g">Tus notas se arrastran. Al tocar una, cambiás fuente y color.</span></p>
	{#if error}<p class="e1">{error}</p>{/if}
</form>

<style>
	.tablero { position: relative; height: calc(var(--linea) * 20); overflow: hidden; background: var(--campo); border-radius: 8px; }
	.nota {
		position: absolute;
		width: 200px;
		left: calc(var(--x) * (100% - 200px));
		top: calc(var(--y) * (100% - var(--linea) * 3));
		display: flex;
		flex-direction: column;
		padding: 0 4px;
		white-space: pre-wrap;
		overflow-wrap: anywhere;
		user-select: none;
	}
	.nota.mia { cursor: grab; touch-action: none; }
	.nota.mia:active { cursor: grabbing; }
	.opcion { background: none; padding: 0; border-radius: 0; }
	.medio { margin-top: 11px; }
	@media (max-width: 760px) {
		.nota { width: 160px; left: calc(var(--x) * (100% - 160px)); }
	}
</style>
