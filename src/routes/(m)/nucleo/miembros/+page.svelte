<script lang="ts">
	import { enhance } from '$app/forms';
	import NucleoMenu from '$lib/components/NucleoMenu.svelte';
	import { fecha, hora } from '$lib/formato';
	let { data, form } = $props();

	const activos = $derived(data.miembros.filter((m) => m.estado === 'activo'));
	const expulsados = $derived(data.miembros.filter((m) => m.estado !== 'activo'));
	const nombre = $derived(new Map(data.titulos.map((t) => [t.id, t.nombre])));

	// Quién tiene cada título: asignados y cargos guardados; derivados calculados.
	const portadores = (id: string) =>
		data.miembros.filter((m) => (id === 'utopico' ? m.utopico : id === 'testigo' ? m.testigo : m.titulos.includes(id)));
	const titulosDe = (m: (typeof data.miembros)[number]) =>
		[...m.titulos.map((t) => nombre.get(t) ?? t), ...(m.utopico ? ['miembro utópico'] : []), ...(m.testigo ? ['miembro testigo'] : [])];
</script>

<svelte:head><title>Miembros · Núcleo · Sociedad Hexagonal</title></svelte:head>

<NucleoMenu />

<section class="L e2">
	<h2>Miembros</h2>
	<div><table><tbody>
		<tr><td class="g">activos</td><td class="d">{activos.length}</td></tr>
		<tr><td class="g">expulsados</td><td class="d">{expulsados.length}</td></tr>
		<tr><td class="g">por entrar</td><td class="d">{data.admision.length}</td></tr>
	</tbody></table></div>
</section>

<section class="L e2">
	<h2>Cargos y títulos</h2>
	<div class="tabla"><table><tbody>
		{#each data.titulos as t (t.id)}
			{@const quienes = portadores(t.id)}
			<tr>
				<td class="nw">{t.nombre}</td>
				<td class="g nw solo-ancho">{t.tipo === 'derivado' ? 'se calcula' : t.tipo}</td>
				<td class="g d">{quienes.length}</td>
				<td>
					{#each quienes as m, i (m.id)}{#if i > 0}{', '}{/if}<a href="/nucleo/miembros/{m.id}" class={m.estado === 'activo' ? '' : 'g'}>{m.alias}</a>{/each}
				</td>
			</tr>
		{/each}
	</tbody></table></div>
</section>

<section class="L e2">
	<h2>Lista</h2>
	{#if data.miembros.length === 0}
		<p class="g">Todavía no entró nadie.</p>
	{:else}
		<div class="tabla"><table><tbody>
			{#each data.miembros as m (m.id)}
				<tr class={m.estado === 'activo' ? '' : 'g'}>
					<td class="nw"><a href="/nucleo/miembros/{m.id}">{m.alias}</a></td>
					<td class="g">{titulosDe(m).join(', ')}</td>
					<td class="g nw solo-ancho">desde {fecha(m.creado)}</td>
					<td class="g nw">{m.estado === 'activo' ? '' : m.estado}</td>
				</tr>
			{/each}
		</tbody></table></div>
	{/if}
</section>

<section class="L e2">
	<h2>Admisión</h2>
	<div>
		<form method="POST" action="?/admitir" use:enhance>
			<label for="lista" class="oculto">Mails</label>
			<textarea id="lista" name="lista" required placeholder="Un mail por línea, o separados por comas.">{form && 'lista' in form ? form.lista : ''}</textarea>
			<p class="fila medio"><button>admitir mails</button><span class="g">Repetidos y lo que no sea un mail se ignoran. Nadie recibe aviso: cada persona pide su enlace en la portada.</span></p>
		</form>
		{#if form && 'admision' in form}<p class="e1">{form.admision}</p>{/if}
		{#if form && 'admitidos' in form && form.admitidos}
			{#if form.admitidos.length === 0}
				<p class="e1">No había mails nuevos.</p>
			{:else}
				<p class="e1">Admitidos: {form.admitidos.length}.</p>
				<div class="tabla"><table><tbody>
					{#each form.admitidos as a (a.email)}<tr><td>{a.email}</td><td class="g">{a.alias}</td></tr>{/each}
				</tbody></table></div>
			{/if}
		{/if}
	</div>
</section>

<section class="L e2">
	<h2>Por entrar</h2>
	<div>
		{#if data.admision.length === 0}
			<p class="g">Todos los admitidos ya entraron.</p>
		{:else}
			<div class="tabla"><table><tbody>
				{#each data.admision as a (a.email)}
					<tr>
						<td>{a.email}</td>
						<td class="g">{a.alias}</td>
						<td class="g nw solo-ancho">{fecha(a.agregado)}</td>
						<td>
							<form method="POST" action="?/quitar" use:enhance>
								<input type="hidden" name="email" value={a.email} />
								<button class="enlace">quitar</button>
							</form>
						</td>
					</tr>
				{/each}
			</tbody></table></div>
		{/if}
		{#if form && 'quitar' in form}<p class="e1">{form.quitar}</p>{/if}
	</div>
</section>

<section class="L e2">
	<h2>Bitácora</h2>
	{#if data.bitacora.length === 0}
		<p class="g">Sin movimientos.</p>
	{:else}
		<div class="tabla"><table><tbody>
			{#each data.bitacora as b (b.id)}
				<tr>
					<td class="g nw">{fecha(b.momento)} {hora(b.momento)}</td>
					<td class="nw">{b.actor?.alias ?? '—'}</td>
					<td class="g nw">{b.accion}</td>
					<td>{b.objetivo}</td>
				</tr>
			{/each}
		</tbody></table></div>
	{/if}
</section>

<style>
	.medio { margin-top: 11px; }
	.enlace { background: none; padding: 0; color: var(--gris); text-decoration: underline; text-decoration-color: var(--subrayado); text-underline-offset: 3px; border-radius: 0; }
</style>
