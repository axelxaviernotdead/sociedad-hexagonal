<script lang="ts">
	import { enhance } from '$app/forms';
	import { partes } from '$lib/citas';
	import { fecha, hora } from '$lib/formato';
	let { data, form } = $props();
	const n4 = (n: number) => String(n).padStart(4, '0');
	let cuerpo = $state('');
	const citar = (n: number) => {
		cuerpo = `${cuerpo}${cuerpo && !cuerpo.endsWith('\n') ? '\n' : ''}>>${n4(n)} `;
		document.getElementById('cuerpo')?.focus();
	};
</script>

<svelte:head><title>{data.hilo.titulo} · Sociedad Hexagonal</title></svelte:head>

<section class="L e3">
	<div><a href="/foro">foro</a> / <a href="/foro?tema={encodeURIComponent(data.hilo.tema)}">{data.hilo.tema}</a></div>
	<div>
		<h1>{data.hilo.titulo}</h1>
		<p class="g">{data.hilo.respuestas} respuestas, abierto por {data.hilo.autor?.alias ?? ''} el {fecha(data.hilo.creado)}</p>
	</div>
</section>

{#each data.mensajes as m (m.numero)}
	<article class="L e1" id={n4(m.numero)}>
		<div>{n4(m.numero)} &nbsp;{m.autor?.alias ?? ''}<br />{fecha(m.creado)} {hora(m.creado)}</div>
		<div>
			<p class="texto cuerpo">{#each partes(m.cuerpo) as x}{#if x.tipo === 'texto'}{x.valor}{:else}<a href="#{n4(x.numero)}">&gt;&gt;{n4(x.numero)}</a>{/if}{/each}</p>
			<button class="enlace" onclick={() => citar(m.numero)}>responder</button>
		</div>
	</article>
{/each}

<form method="POST" use:enhance={() => async ({ result, update }) => { if (result.type === 'success') cuerpo = ''; await update(); }}>
	<div class="L e2">
		<label for="cuerpo">Responder</label>
		<div>
			<textarea id="cuerpo" name="cuerpo" maxlength="20000" placeholder="Texto plano. Para citar: >>número." bind:value={cuerpo}></textarea>
			<div class="fila" style="margin-top:11px"><button>publicar</button><span class="g">se publica con tu alias</span></div>
			{#if form?.error}<p class="e1">{form.error}</p>{/if}
		</div>
	</div>
</form>

<style>
	.cuerpo { white-space: pre-wrap; overflow-wrap: anywhere; }
	.enlace { background: none; padding: 0; color: var(--gris); text-decoration: underline; text-decoration-color: var(--subrayado); text-underline-offset: 3px; border-radius: 0; }
	article:target > div:first-child { color: var(--negro); }
</style>
