<script lang="ts">
	import { enhance } from '$app/forms';
	import { fecha } from '$lib/formato';
	let { data, form } = $props();
	const m = $derived(data.m);
	let confirmando = $state(false);
	const tiene = (id: string) => (id === 'utopico' ? m.utopico : id === 'testigo' ? m.testigo : m.titulos.includes(id));
	const tras = () => async ({ update }: { update: () => Promise<void> }) => { await update(); confirmando = false; };
</script>

<svelte:head><title>{m.alias} · Núcleo · Sociedad Hexagonal</title></svelte:head>

<section class="L e3">
	<div><a href="/nucleo/miembros">miembros</a> / {m.alias}</div>
	<div>
		<h1>{m.alias}</h1>
		<p class="g">Miembro desde {fecha(m.creado)}.{m.estado === 'expulsado' ? ' Expulsado.' : ''}{data.soyYo ? ' Es tu cuenta.' : ''}</p>
	</div>
</section>

<section class="L e2">
	<h2>Títulos y cargos</h2>
	<div class="tabla"><table><tbody>
		{#each data.titulos as t (t.id)}
			{@const si = tiene(t.id)}
			<tr>
				<td class={si ? 'nw' : 'g nw'}>{t.nombre}</td>
				<td class="g">{si ? 'sí' : 'no'}</td>
				<td class="g nw solo-ancho">{t.tipo === 'derivado' ? 'se calcula' : t.tipo}</td>
				<td>
					{#if t.tipo === 'derivado'}
						<span></span>
					{:else if si && data.soyYo && t.id === 'nucleo'}
						<span class="g">no podés sacártelo</span>
					{:else}
						<form method="POST" action={si ? '?/sacar' : '?/dar'} use:enhance>
							<input type="hidden" name="titulo" value={t.id} />
							<button>{si ? 'sacar' : 'dar'}</button>
						</form>
					{/if}
				</td>
			</tr>
		{/each}
	</tbody></table></div>
</section>

<section class="L e2">
	<h2>Estado</h2>
	<div>
		{#if data.soyYo}
			<p class="g">No podés cambiar tu propio estado.</p>
		{:else if m.estado === 'activo'}
			<form method="POST" action="?/estado" use:enhance={tras} class="fila">
				<input type="hidden" name="estado" value="expulsado" />
				{#if confirmando}
					<button>confirmar expulsión</button>
					<button type="button" class="enlace" onclick={() => (confirmando = false)}>no expulsar</button>
				{:else}
					<button type="button" onclick={() => (confirmando = true)}>expulsar</button>
				{/if}
				<span class="g">Pierde el acceso al sitio y sus cargos dejan de valer. Se puede readmitir.</span>
			</form>
		{:else}
			<form method="POST" action="?/estado" use:enhance class="fila">
				<input type="hidden" name="estado" value="activo" />
				<button>readmitir</button>
				<span class="g">Vuelve a entrar con sus títulos y cargos.</span>
			</form>
		{/if}
	</div>
</section>

{#if form?.error}<div class="L e1"><div></div><p>{form.error}</p></div>{/if}

<style>
	.enlace { background: none; padding: 0; color: var(--gris); text-decoration: underline; text-decoration-color: var(--subrayado); text-underline-offset: 3px; border-radius: 0; }
</style>
