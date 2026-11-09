<script lang="ts">
	import { enhance } from '$app/forms';
	import { fecha, n2, n3 } from '$lib/formato';
	let { data, form } = $props();
	const r = $derived(data.r);
	let editando = $state(false);
</script>

<svelte:head><title>Registro · Sociedad Hexagonal</title></svelte:head>

<section class="L negro e3"><h1>Registro</h1><p>{r.alias}</p></section>

<section class="L e2">
	<h2>Datos</h2>
	<table><tbody>
		<tr><td class="g">alias</td><td>{r.alias} &nbsp;<button class="enlace" onclick={() => (editando = !editando)}>cambiar</button></td></tr>
		<tr><td class="g">mail</td><td>{r.email}</td></tr>
		<tr><td class="g">miembro desde</td><td>{fecha(r.creado)}</td></tr>
		<tr><td class="g">títulos</td><td>{r.titulos.length ? r.titulos.join(', ') : '—'}</td></tr>
	</tbody></table>
	{#if editando || form?.error}
		<div></div>
		<form method="POST" action="?/alias" use:enhance class="fila e1">
			<label for="alias" class="oculto">Nuevo alias</label>
			<input id="alias" name="alias" value={form?.alias ?? r.alias} style="max-width:240px" />
			<button>guardar</button>
			{#if form?.error}<span>{form.error}</span>{/if}
		</form>
	{/if}
</section>

<section class="L e2">
	<h2>Asistencia</h2>
	{#if r.asistencia.length}
		<div>
			<p class="fila">{#each r.asistencia as a}<span class={a.presente ? '' : 'g'}>N°{n2(a.numero)}</span>{/each}</p>
			<p class="g">{r.asistencia.filter((a) => a.presente).length} de {r.asistencia.length}. Lo ven solo vos y secretaría.</p>
		</div>
	{:else}
		<p class="g">Todavía no hay utopías realizadas.</p>
	{/if}
</section>

<section class="L e2">
	<h2>Presentaciones</h2>
	{#if r.presentaciones.length}
		<table><tbody>
			{#each r.presentaciones as p}
				<tr><td class="g">{n3(p.numero)}</td><td><a href="/p/{p.numero}">{p.titulo}</a></td><td class="g nw">N°{n2(p.utopia)}, visible para {p.visibilidad === 'publico' ? 'público' : 'miembros'}</td></tr>
			{/each}
		</tbody></table>
	{:else}
		<p class="g">Ninguna todavía.</p>
	{/if}
</section>

<style>
	.enlace { background: none; padding: 0; color: var(--gris); text-decoration: underline; text-decoration-color: var(--subrayado); text-underline-offset: 3px; border-radius: 0; }
</style>
