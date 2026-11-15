<script lang="ts">
	import { page } from '$app/state';
	const SECCIONES = [
		{ ruta: '/nucleo', nombre: 'utopías y calendario' },
		{ ruta: '/nucleo/miembros', nombre: 'miembros' }
	];
	const actual = (r: string) => (r === '/nucleo' ? !page.url.pathname.startsWith('/nucleo/miembros') : page.url.pathname.startsWith(r));
</script>

<section class="L negro e3">
	<h1>Núcleo</h1>
	<nav class="fila" aria-label="Secciones del núcleo">
		{#each SECCIONES as s}
			<a href={s.ruta} class={actual(s.ruta) ? '' : 'g'} aria-current={actual(s.ruta) ? 'page' : undefined}>{s.nombre}</a>
		{/each}
	</nav>
</section>
