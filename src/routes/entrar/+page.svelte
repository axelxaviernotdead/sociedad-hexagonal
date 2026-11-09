<script lang="ts">
	let { form } = $props();
</script>

<svelte:head><title>Acceso · Sociedad Hexagonal</title></svelte:head>

<section class="L negro acceso">
	<h1>Acceso</h1>
	<div>
		{#if form?.enviado}
			<p class="texto">Si el mail figura en la lista de admisión, te llegó un enlace de acceso. Vence en una hora.</p>
		{:else}
			<p class="texto">Ingresá tu mail. Si figura en la lista de admisión, recibís un enlace de acceso.</p>
			<form method="POST" class="e1">
				<label for="email" class="oculto">Mail</label>
				<input id="email" name="email" type="email" autocomplete="email" required placeholder="nombre@dominio.com" value={form?.email ?? ''} style="max-width:320px" />
				{#if form?.error}<p class="e1">{form.error}</p>{/if}
				<button class="e1">enviar enlace</button>
			</form>
			<p class="g e2">No hay registro abierto ni contraseñas.</p>
		{/if}
	</div>
</section>

<style>
	.acceso { margin-top: calc(var(--linea) * 10); }
	button.e1 { margin-top: 11px; }
</style>
