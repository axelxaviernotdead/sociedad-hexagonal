<script lang="ts">
	let { form } = $props();
</script>

<svelte:head><title>Sociedad Hexagonal</title></svelte:head>

<!-- Excepción a la alineación a la izquierda (DESIGN.md): la portada de acceso va centrada. -->
<section class="acceso">
	<h1>Sociedad Hexagonal</h1>
	{#if form?.enviado}
		<p class="e1">Si el mail está admitido, te llegó un enlace de acceso.</p>
	{:else}
		<form method="POST" class="e1">
			<label for="email" class="oculto">Mail</label>
			<input id="email" name="email" type="email" autocomplete="email" required placeholder="nombre@dominio.com" value={form?.email ?? ''} />
			<button class="medio">enviar enlace</button>
			{#if form?.error}<p class="e1">{form.error}</p>{/if}
		</form>
	{/if}
</section>

<style>
	.acceso {
		/* main deja 4 líneas abajo; se descuentan para que no aparezca scroll. */
		min-height: calc(100svh - var(--linea) * 4);
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		text-align: center;
		padding: 0 var(--margen);
	}
	form { width: 100%; max-width: 320px; }
	.medio { margin-top: 11px; }
</style>
