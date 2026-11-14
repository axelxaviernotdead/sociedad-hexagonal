<script lang="ts">
	import { enhance } from '$app/forms';
	import { fechaCampo, horaCampo, n2 } from '$lib/formato';
	let { data, form } = $props();
	const u = $derived(data.u);
	const v = $derived({
		numero: form && 'numero' in form ? form.numero : String(u?.numero ?? data.siguiente),
		fecha: form && 'fecha' in form ? form.fecha : u ? fechaCampo(u.fecha) : '',
		hora: form && 'hora' in form ? form.hora : u ? horaCampo(u.fecha) : '19:00',
		estado: form && 'estado' in form ? form.estado : (u?.estado ?? 'anunciada'),
		lugar: form && 'lugar' in form ? form.lugar : data.lugar
	});
	let confirmando = $state(false);
</script>

<svelte:head><title>{u ? `Utopía N°${n2(u.numero)}` : 'Nueva utopía'} · Sociedad Hexagonal</title></svelte:head>

<section class="L e3">
	<div><a href="/nucleo">núcleo</a> / {u ? `N°${n2(u.numero)}` : 'nueva'}</div>
	<div>
		<h1>{u ? `Utopía N°${n2(u.numero)}` : 'Nueva utopía'}</h1>
		{#if u}<p class="g">{data.confirmados} confirmados</p>{:else}<p class="g">Se crea también su evento en el calendario.</p>{/if}
	</div>
</section>

<form method="POST" action="?/guardar" use:enhance>
	<div class="L e2"><label for="numero">Número</label><input id="numero" name="numero" type="number" min="1" max="999" required value={v.numero} style="max-width:120px" /></div>
	<div class="L e1">
		<label for="fecha">Fecha</label>
		<div class="fila">
			<input id="fecha" name="fecha" type="date" required value={v.fecha} style="max-width:180px" />
			<label for="hora" class="oculto">Hora</label>
			<input id="hora" name="hora" type="time" value={v.hora} style="max-width:120px" />
		</div>
	</div>
	{#if u}
		<div class="L e1">
			<label for="estado">Estado</label>
			<select id="estado" name="estado" style="max-width:180px">
				<option value="anunciada" selected={v.estado === 'anunciada'}>anunciada</option>
				<option value="realizada" selected={v.estado === 'realizada'}>realizada</option>
			</select>
		</div>
	{/if}
	<div class="L e1">
		<label for="lugar">Lugar</label>
		<div>
			<textarea id="lugar" name="lugar" maxlength="500" placeholder="Dirección y cómo entrar.">{v.lugar}</textarea>
			<p class="g medio">Lo ven solo quienes confirmaron, desde 48 h antes. Vacío: se informa más adelante.</p>
		</div>
	</div>
	<div class="L e1"><div></div><div class="fila"><button>guardar</button><a href="/nucleo" class="g">cancelar</a></div></div>
	{#if form?.error}<div class="L e1"><div></div><p>{form.error}</p></div>{/if}
</form>

{#if u && u.estado === 'anunciada'}
	<section class="L e3">
		<h2>Eliminar</h2>
		<form method="POST" action="?/eliminar" use:enhance class="fila">
			{#if confirmando}
				<button>confirmar eliminación</button>
				<button type="button" class="enlace" onclick={() => (confirmando = false)}>no eliminar</button>
				<span class="g">Se borran también su evento, su lugar y las confirmaciones.</span>
			{:else}
				<button type="button" onclick={() => (confirmando = true)}>eliminar utopía</button>
				<span class="g">Solo si todavía no se hizo.</span>
			{/if}
		</form>
	</section>
{/if}

<style>
	.medio { margin-top: 11px; }
	.enlace { background: none; padding: 0; color: var(--gris); text-decoration: underline; text-decoration-color: var(--subrayado); text-underline-offset: 3px; border-radius: 0; }
</style>
