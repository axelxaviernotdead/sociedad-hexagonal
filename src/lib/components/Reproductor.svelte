<script lang="ts">
	import { reproductor as r } from '$lib/reproductor.svelte';
	import { duracion, n3 } from '$lib/formato';

	let audio = $state<HTMLAudioElement>();

	$effect(() => {
		if (!audio || r.pedido === null) return;
		audio.currentTime = r.pedido;
		r.pedido = null;
	});

	$effect(() => {
		if (!audio || !r.pista) return;
		if (r.sonando) audio.play().catch(() => (r.sonando = false));
		else audio.pause();
	});
</script>

{#if r.pista}
	<div class="L barra" role="region" aria-label="Reproductor">
		<div class="solo-ancho">en reproducción</div>
		<div class="fila">
			<button onclick={() => (r.sonando = !r.sonando)}>{r.sonando ? 'pausa' : 'reproducir'}</button>
			<span><span class="g">{n3(r.pista.numero)}</span> &nbsp;{r.pista.titulo} &nbsp;<span class="g">{r.pista.alias ?? ''}</span></span>
			<span class="g derecha">{duracion(r.tiempo)} / {duracion(r.total)}</span>
			<button onclick={() => r.cerrar()}>cerrar</button>
		</div>
		<audio
			bind:this={audio}
			src={r.pista.url}
			preload="metadata"
			ontimeupdate={(e) => (r.tiempo = e.currentTarget.currentTime)}
			onloadedmetadata={(e) => (r.total = e.currentTarget.duration)}
			onended={() => (r.sonando = false)}
		></audio>
	</div>
{/if}

<style>
	.barra {
		position: fixed;
		left: 0;
		right: 0;
		bottom: 0;
		padding-top: var(--linea);
		padding-bottom: var(--linea);
		background: var(--fondo);
	}
	.derecha { margin-left: auto; }
	audio { display: none; }
</style>
