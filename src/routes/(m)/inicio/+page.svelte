<script lang="ts">
	import { enhance } from '$app/forms';
	import Archivo from '$lib/components/Archivo.svelte';
	import { fecha, dia, hora, n2 } from '$lib/formato';
	let { data, form } = $props();
	const u = $derived(data.utopia);
</script>

<svelte:head><title>Inicio · Sociedad Hexagonal</title></svelte:head>

<section class="L e3" id="calendario">
	<h2>Calendario</h2>
	{#if data.eventos.length === 0}
		<p class="g">No hay actividades programadas.</p>
	{:else}
		<div class="tabla">
			<table>
				<tbody>
					{#each data.eventos as e (e.id)}
						{@const principal = u && e.utopia_id === u.id}
						<tr class={principal ? '' : 'g'}>
							<td class="g nw">{fecha(e.fecha)} {dia(e.fecha)} {hora(e.fecha)}</td>
							<td>
								{e.titulo}
								{#if e.detalle}&nbsp;<span class="g">{e.detalle}</span>{/if}
								{#if principal}
									<br />
									{#if u.lugar}<span>Lugar: {u.lugar}</span><br />{:else}<span class="g">Lugar: se informa 48 h antes a quienes confirmen.</span><br />{/if}
									<span class="g">{u.confirmados} confirmados</span>&nbsp;
									<form method="POST" action="?/asistencia" use:enhance style="display:inline">
										<input type="hidden" name="utopia_id" value={u.id} />
										<button name="estado" value="asistire" class={u.estado === 'asistire' ? 'activo' : ''}>asistiré</button>
										<button name="estado" value="no_asistire" class={u.estado === 'no_asistire' ? 'activo' : ''}>no asistiré</button>
									</form>
									{#if form?.error}<br />{form.error}{/if}
								{/if}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
	{#if u && !data.eventos.some((e) => e.utopia_id === u.id)}
		<p class="g e1">Próxima: Utopía N°{n2(u.numero)}, {fecha(u.fecha)}.</p>
	{/if}
</section>

<section class="L e2">
	<h2>Archivo</h2>
	<Archivo items={data.archivo} limite={20} />
</section>
