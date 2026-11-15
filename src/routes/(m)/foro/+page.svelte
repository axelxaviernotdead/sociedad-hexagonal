<script lang="ts">
	import { hace } from '$lib/formato';
	let { data } = $props();
	const enlace = (cambios: Record<string, string | number | null>) => {
		const p = new URLSearchParams();
		const v = { tema: data.tema, orden: data.orden, ...cambios };
		if (v.tema) p.set('tema', String(v.tema));
		if (v.orden && v.orden !== 'actividad') p.set('orden', String(v.orden));
		if (cambios.p) p.set('p', String(cambios.p));
		const s = p.toString();
		return s ? `?${s}` : '/foro';
	};
</script>

<svelte:head><title>Foro · Sociedad Hexagonal</title></svelte:head>

<div class="L e3">
	<nav class="temas" aria-label="Temas">
		<a href={enlace({ tema: null })} class={data.tema ? 'g' : 'sel'}>todos</a>
	</nav>
	<div>
		<div class="fila">
			{#each ['actividad', 'nuevos', 'respuestas'] as o}
				<a href={enlace({ orden: o })} class={data.orden === o ? '' : 'g'}>{o}</a>
			{/each}
			<a class="btn derecha" href="/foro/nuevo">nuevo hilo</a>
		</div>

		{#if data.hilos.length === 0}
			<p class="g e2">No hay hilos{data.tema ? ` sobre ${data.tema}` : ''}.</p>
		{:else}
			<div class="tabla e2">
				<table><tbody>
					{#each data.hilos as h, i (h.id)}
						<tr>
							<td class="g d">{data.desde + i + 1}</td>
							<td class="titulo"><a href="/foro/{h.id}">{h.titulo}</a></td>
							<td class="g nw solo-ancho">{h.tema}</td>
							<td class="g d">{h.respuestas}</td>
							<td class="g nw solo-ancho">{h.autor?.alias ?? ''}</td>
							<td class="g d nw">{hace(h.actividad)}</td>
						</tr>
					{/each}
				</tbody></table>
			</div>
		{/if}
		{#if data.hayMas}<a class="g e2" style="display:inline-block" href={enlace({ p: data.pagina + 1 })}>siguiente página</a>{/if}
	</div>
</div>

<style>
	.temas { display: flex; flex-direction: column; align-items: flex-start; }
	.temas .sel { color: var(--negro); text-decoration: none; }
	.derecha { margin-left: auto; }
	.titulo { min-width: 320px; }
	@media (max-width: 760px) {
		.temas { flex-direction: row; flex-wrap: wrap; gap: 0 16px; }
		.titulo { min-width: 0; }
	}
</style>
