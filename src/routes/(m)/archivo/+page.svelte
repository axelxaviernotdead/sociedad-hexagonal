<script lang="ts">
	import Archivo from '$lib/components/Archivo.svelte';
	let { data } = $props();
</script>

<svelte:head><title>Archivo · Sociedad Hexagonal</title></svelte:head>

<section class="L e3">
	<h1>Archivo</h1>
	<Archivo items={data.archivo} />
</section>
