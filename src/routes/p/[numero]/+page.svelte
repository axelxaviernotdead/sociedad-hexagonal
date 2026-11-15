<script lang="ts">
	import { enhance } from '$app/forms';
	import { page } from '$app/state';
	import { reproductor } from '$lib/reproductor.svelte';
	import { duracion, fecha, n2, n3 } from '$lib/formato';
	let { data, form } = $props();
	const p = $derived(data.p);
	let video = $state<HTMLVideoElement>();

	function escuchar(desde: number | null = null) {
		if (!data.urls.audio) return;
		reproductor.cargar({ numero: p.numero, titulo: p.titulo, alias: p.alias, url: data.urls.audio }, desde);
		reproductor.sonando = true;
	}
	function ir(t: number) {
		if (video) {
			video.currentTime = t;
			video.play();
		} else escuchar(t);
	}
</script>

<svelte:head><title>{p.titulo} · Sociedad Hexagonal</title></svelte:head>

<section class="L e3">
	<div><a href={page.data.alias ? '/archivo' : '/'}>archivo</a> / {n3(p.numero)}</div>
	<div>
		<h1>{p.titulo}</h1>
		<p class="g">{p.alias ?? ''}, utopía N°{n2(p.utopia)}, {fecha(p.fecha)}</p>
	</div>
</section>

{#if data.urls.video}
	<section class="L e1">
		<div></div>
		<!-- svelte-ignore a11y_media_has_caption -->
		<video bind:this={video} src={data.urls.video} controls preload="metadata" controlslist="nodownload" class="video"></video>
	</section>
{/if}

<section class="L e1">
	<div></div>
	<div class="fila">
		{#if data.urls.audio}<button onclick={() => escuchar()}>escuchar audio</button>{/if}
		{#if data.urls.diapositivas}<a class="btn" href={data.urls.diapositivas} target="_blank" rel="noopener">diapositivas</a>{/if}
		{#if !data.urls.audio && !data.urls.video}<span class="g">Grabación no disponible todavía.</span>{/if}
	</div>
</section>

<div class="columnas e2">
	{#if p.capitulos.length}
		<section>
			<h2 class="g">Contenido</h2>
			<table><tbody>
				{#each p.capitulos as c}
					<tr><td class="g">{duracion(c.t)}</td><td><a href="#{c.t}" onclick={(e) => { e.preventDefault(); ir(c.t); }}>{c.titulo}</a></td></tr>
				{/each}
			</tbody></table>
		</section>
	{/if}
	<section>
		<h2 class="g">Ficha</h2>
		<table><tbody>
			<tr><td class="g">duración</td><td>{duracion(p.duracion_s)}</td></tr>
			{#if p.temas.length}<tr><td class="g">temas</td><td>{p.temas.join(', ')}</td></tr>{/if}
			<tr><td class="g">visible para</td><td>{p.visibilidad === 'publico' ? 'público' : 'miembros'}</td></tr>
		</tbody></table>
		{#if p.es_mia}
			<form method="POST" action="?/visibilidad" use:enhance class="e1">
				<input type="hidden" name="visibilidad" value={p.visibilidad === 'publico' ? 'miembros' : 'publico'} />
				<button>{p.visibilidad === 'publico' ? 'hacer solo para miembros' : 'hacer pública'}</button>
			</form>
			{#if form?.error}<p class="e1">{form.error}</p>{/if}
		{/if}
	</section>
	{#if p.resumen}
		<section class="resumen">
			<h2 class="g">Resumen</h2>
			<p>{p.resumen}</p>
		</section>
	{/if}
</div>

<style>
	.video { width: 100%; max-width: 1000px; aspect-ratio: 16 / 9; background: #111; display: block; }
	.columnas {
		display: flex; flex-wrap: wrap; gap: var(--linea) 64px;
		padding-left: calc(var(--margen) + var(--rotulo) + var(--margen)); padding-right: var(--margen);
	}
	.resumen { max-width: 360px; }
	@media (max-width: 760px) { .columnas { padding-left: var(--margen); } }
</style>
