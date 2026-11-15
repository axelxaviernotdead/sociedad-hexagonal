<script lang="ts">
	import '../app.css';
	import { page } from '$app/state';
	import Reproductor from '$lib/components/Reproductor.svelte';
	import { reproductor } from '$lib/reproductor.svelte';

	let { data, children } = $props();

	const menu = $derived([
		{ ruta: '/inicio', nombre: 'archivo' },
		{ ruta: '/foro', nombre: 'foro' },
		{ ruta: '/inicio#calendario', nombre: 'calendario' },
		{ ruta: '/registro', nombre: 'registro' },
		...(data.nucleo ? [{ ruta: '/nucleo', nombre: 'núcleo' }] : [])
	]);
	const actual = (ruta: string) => {
		const base = ruta.split('#')[0];
		if (ruta.includes('#')) return false;
		return base === '/' ? page.url.pathname === '/' : page.url.pathname.startsWith(base) || (base === '/inicio' && page.url.pathname.startsWith('/p/'));
	};
</script>

<header class="L cabecera">
	<div class="negro-fijo"><a href={data.alias ? '/inicio' : '/'} class="marca">Sociedad Hexagonal</a></div>
	{#if data.alias}
		<nav class="fila">
			{#each menu as m}
				<a href={m.ruta} class={actual(m.ruta) ? '' : 'g'} aria-current={actual(m.ruta) ? 'page' : undefined}>{m.nombre}</a>
			{/each}
			<span class="derecha g">
				{data.alias}
				<form method="POST" action="/salir" style="display:inline"><button class="enlace">salir</button></form>
			</span>
		</nav>
	{/if}
</header>

<main class:con-reproductor={reproductor.pista}>
	{@render children()}
</main>

<Reproductor />

<style>
	.cabecera { padding-top: 24px; }
	.negro-fijo { color: var(--negro) !important; }
	.marca { text-decoration: none; }
	.derecha { margin-left: auto; }
	.enlace { background: none; padding: 0; color: var(--gris); text-decoration: underline; text-decoration-color: var(--subrayado); text-underline-offset: 3px; border-radius: 0; }
	main { padding-bottom: calc(var(--linea) * 4); }
	main.con-reproductor { padding-bottom: calc(var(--linea) * 6); }
</style>
