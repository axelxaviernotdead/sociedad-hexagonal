<script lang="ts">
	import { enhance } from '$app/forms';
	import { fecha, dia, hora, fechaCampo, horaCampo, n2 } from '$lib/formato';
	let { data, form } = $props();
	const e = $derived(data.e);
	const v = $derived({
		titulo: form && 'titulo' in form ? form.titulo : (e?.titulo ?? ''),
		detalle: form && 'detalle' in form ? form.detalle : (e?.detalle ?? ''),
		fecha: form && 'fecha' in form ? form.fecha : e ? fechaCampo(e.fecha) : '',
		hora: form && 'hora' in form ? form.hora : e ? horaCampo(e.fecha) : ''
	});
	let confirmando = $state(false);
</script>

<svelte:head><title>{e ? e.titulo : 'Nuevo evento'} · Sociedad Hexagonal</title></svelte:head>

<section class="L e3">
	<div><a href="/nucleo">núcleo</a> / {e ? 'evento' : 'nuevo evento'}</div>
	<div>
		<h1>{e ? e.titulo : 'Nuevo evento'}</h1>
		{#if data.utopia}<p class="g">Evento de la <a href="/nucleo/utopias/{data.utopia}">utopía N°{n2(data.utopia)}</a>.</p>{/if}
	</div>
</section>

<form method="POST" action="?/guardar" use:enhance>
	{#if e?.utopia_id}
		<div class="L e2"><div>Fecha</div><p>{fecha(e.fecha)} {dia(e.fecha)} {hora(e.fecha)} <span class="g">Se cambia en la utopía.</span></p></div>
	{:else}
		<div class="L e2">
			<label for="fecha">Fecha</label>
			<div>
				<div class="fila">
					<input id="fecha" name="fecha" type="date" required value={v.fecha} style="max-width:180px" />
					<label for="hora" class="oculto">Hora</label>
					<input id="hora" name="hora" type="time" value={v.hora} style="max-width:120px" />
				</div>
				<p class="g medio">Sin hora: se muestra solo el día.</p>
			</div>
		</div>
	{/if}
	<div class="L e1"><label for="titulo">Título</label><input id="titulo" name="titulo" required maxlength="160" value={v.titulo} /></div>
	<div class="L e1"><label for="detalle">Detalle</label><input id="detalle" name="detalle" maxlength="300" value={v.detalle} placeholder="Opcional. Por ejemplo: operadores y músicos." /></div>
	<div class="L e1"><div></div><div class="fila"><button>guardar</button><a href="/nucleo" class="g">cancelar</a></div></div>
	{#if form?.error}<div class="L e1"><div></div><p>{form.error}</p></div>{/if}
</form>

{#if e && !e.utopia_id}
	<section class="L e3">
		<h2>Eliminar</h2>
		<form method="POST" action="?/eliminar" use:enhance class="fila">
			{#if confirmando}
				<button>confirmar eliminación</button>
				<button type="button" class="enlace" onclick={() => (confirmando = false)}>no eliminar</button>
			{:else}
				<button type="button" onclick={() => (confirmando = true)}>eliminar evento</button>
			{/if}
		</form>
	</section>
{/if}

<style>
	.medio { margin-top: 11px; }
	.enlace { background: none; padding: 0; color: var(--gris); text-decoration: underline; text-decoration-color: var(--subrayado); text-underline-offset: 3px; border-radius: 0; }
</style>
