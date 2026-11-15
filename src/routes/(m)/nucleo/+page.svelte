<script lang="ts">
	import { fecha, dia, hora, n2 } from '$lib/formato';
	import NucleoMenu from '$lib/components/NucleoMenu.svelte';
	let { data } = $props();
</script>

<svelte:head><title>Núcleo · Sociedad Hexagonal</title></svelte:head>

<NucleoMenu />

<section class="L e2">
	<h2>Utopías</h2>
	<div>
		<a class="btn" href="/nucleo/utopias/nueva">nueva utopía</a>
		{#if data.utopias.length === 0}
			<p class="g e1">Todavía no hay utopías.</p>
		{:else}
			<div class="tabla e1">
				<table><tbody>
					{#each data.utopias as u (u.id)}
						<tr class={u.estado === 'anunciada' ? '' : 'g'}>
							<td><a href="/nucleo/utopias/{u.numero}">N°{n2(u.numero)}</a></td>
							<td class="g nw">{fecha(u.fecha)} {dia(u.fecha)} {hora(u.fecha)}</td>
							<td class="g solo-ancho">{u.estado}</td>
							{#if u.estado === 'anunciada'}
								<td class="g nw">{u.lugar ? 'lugar cargado' : 'sin lugar'}</td>
								<td class="g d nw solo-ancho">{u.confirmados} confirmados</td>
							{:else}
								<td></td><td class="solo-ancho"></td>
							{/if}
						</tr>
					{/each}
				</tbody></table>
			</div>
		{/if}
	</div>
</section>

<section class="L e2">
	<h2>Calendario</h2>
	<div>
		<a class="btn" href="/nucleo/eventos/nuevo">nuevo evento</a>
		{#if data.eventos.length === 0}
			<p class="g e1">No hay actividades programadas.</p>
		{:else}
			<div class="tabla e1">
				<table><tbody>
					{#each data.eventos as e (e.id)}
						<tr class={e.utopia_id ? '' : 'g'}>
							<td class="g nw">{fecha(e.fecha)} {dia(e.fecha)} {hora(e.fecha)}</td>
							<td><a href="/nucleo/eventos/{e.id}">{e.titulo}</a>{#if e.detalle}&nbsp; <span class="g">{e.detalle}</span>{/if}</td>
						</tr>
					{/each}
				</tbody></table>
			</div>
		{/if}
	</div>
</section>
