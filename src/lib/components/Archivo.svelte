<script lang="ts">
	import { duracion, n3, n2 } from '$lib/formato';
	export type Item = { numero: number; titulo: string; alias: string | null; utopia: number; duracion_s: number | null; audio: boolean; video: boolean };
	let { items, limite = Infinity }: { items: Item[]; limite?: number } = $props();
	let todos = $state(false);
	const visibles = $derived(todos ? items : items.slice(0, limite));
</script>

{#if items.length === 0}
	<p class="g">Todavía no hay presentaciones.</p>
{:else}
	<div class="tabla">
		<table>
			<tbody>
				{#each visibles as p (p.numero)}
					<tr>
						<td class="g">{n3(p.numero)}</td>
						<td class="titulo"><a href="/p/{p.numero}">{p.titulo}</a></td>
						<td class="g nw">{p.alias ?? ''}</td>
						<td class="g nw">N°{n2(p.utopia)}</td>
						<td class="g nw solo-ancho">{[p.audio && 'audio', p.video && 'video'].filter(Boolean).join(', ')}</td>
						<td class="g d">{duracion(p.duracion_s)}</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
	{#if items.length > visibles.length}
		<button class="e1" onclick={() => (todos = true)}>{items.length - visibles.length} más</button>
	{/if}
{/if}

<style>
	.titulo { min-width: 280px; }
	@media (max-width: 760px) { .titulo { min-width: 0; } }
</style>
