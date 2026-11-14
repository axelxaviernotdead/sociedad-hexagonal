<script lang="ts">
	let { form } = $props();
</script>

<svelte:head><title>Sociedad Hexagonal</title></svelte:head>

<section class="L acceso">
	<div></div>
	{#if form?.enviado}
		<p>Si el mail está admitido, te llegó un enlace de acceso.</p>
	{:else}
		<form method="POST">
			<label for="email" class="oculto">Mail</label>
			<input id="email" name="email" type="email" autocomplete="email" required placeholder="nombre@dominio.com" value={form?.email ?? ''} style="max-width:320px" />
			<button class="medio">enviar enlace</button>
			{#if form?.error}<p class="e1">{form.error}</p>{/if}
		</form>
	{/if}
</section>

<style>
	.acceso { margin-top: calc(var(--linea) * 10); }
	.medio { margin-top: 11px; }
</style>
