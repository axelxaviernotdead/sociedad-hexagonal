<script lang="ts">
	import { TEMAS } from '$lib/temas';
	let { form } = $props();
</script>

<svelte:head><title>Nuevo hilo · Sociedad Hexagonal</title></svelte:head>

<section class="L e3"><div><a href="/foro">foro</a> / nuevo</div><h1>Nuevo hilo</h1></section>

<form method="POST">
	<div class="L e2"><label for="titulo">Título</label><input id="titulo" name="titulo" required minlength="3" maxlength="160" value={form?.titulo ?? ''} /></div>
	<div class="L e1">
		<label for="tema">Tema</label>
		<select id="tema" name="tema" required style="max-width:320px">
			<option value="" disabled selected={!form?.tema}>elegí un tema</option>
			{#each TEMAS as t}<option value={t} selected={form?.tema === t}>{t}</option>{/each}
		</select>
	</div>
	<div class="L e1"><label for="cuerpo">Mensaje</label><textarea id="cuerpo" name="cuerpo" required maxlength="20000" placeholder="Texto plano. Para citar: >>número.">{form?.cuerpo ?? ''}</textarea></div>
	<div class="L e1"><div></div><div class="fila"><button>publicar</button><span class="g">se publica con tu alias</span></div></div>
	{#if form?.error}<div class="L e1"><div></div><p>{form.error}</p></div>{/if}
</form>
