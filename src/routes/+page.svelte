<script lang="ts">
	import Archivo from '$lib/components/Archivo.svelte';
	import { fecha } from '$lib/formato';
	let { data } = $props();
</script>

<svelte:head><title>Sociedad Hexagonal</title></svelte:head>

<section class="L negro e3">
	<h1>Sociedad Hexagonal</h1>
	<p class="texto">
		Organiza las Utopías: encuentros en Buenos Aires donde sus miembros presentan y discuten ideas sobre energía,
		mente, internet, economía, música, culturas y otros temas. Las presentaciones se graban. Este es el archivo de las
		que sus autores decidieron publicar.
	</p>
</section>

{#if data.datos}
	<section class="L e2">
		<h2>Datos</h2>
		<table>
			<tbody>
				{#if data.datos.primera}<tr><td class="g">primera utopía</td><td>{fecha(data.datos.primera)}</td></tr>{/if}
				<tr><td class="g">utopías realizadas</td><td>{data.datos.realizadas}</td></tr>
				<tr><td class="g">presentaciones públicas</td><td>{data.datos.publicas} de {data.datos.total}</td></tr>
				<tr><td class="g">ingreso</td><td>cerrado</td></tr>
			</tbody>
		</table>
	</section>
{/if}

<section class="L e2">
	<h2>Archivo público</h2>
	<Archivo items={data.archivo} />
</section>

<footer class="L e3"><div></div><p class="g">Sin cookies de seguimiento. Sin analítica.</p></footer>
