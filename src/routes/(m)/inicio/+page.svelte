<script lang="ts">
	import { enhance } from '$app/forms';
	import { fecha, dia, hora, hace, n2, diaDelMes } from '$lib/formato';
	let { data, form } = $props();
	const u = $derived(data.utopia);
	const s = $derived(data.siguiente);

	// Celdas del mes: vacías hasta el primer día, después un día por celda con sus eventos.
	const celdas = $derived.by(() => {
		const porDia = new Map<number, typeof data.delMes>();
		for (const e of data.delMes) {
			const d = diaDelMes(e.fecha);
			porDia.set(d, [...(porDia.get(d) ?? []), e]);
		}
		return [
			...Array.from({ length: data.mes.semanaInicio }, () => null),
			...Array.from({ length: data.mes.dias }, (_, i) => ({ dia: i + 1, eventos: porDia.get(i + 1) ?? [] }))
		];
	});
	const SEMANA = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
</script>

<svelte:head><title>Inicio · Sociedad Hexagonal</title></svelte:head>

<section class="L e3" id="calendario">
	<h2>Calendario</h2>
	<div>
		<p class="mayuscula">{data.mes.nombre} {data.mes.anio}</p>
		<div class="mes e1" role="table" aria-label="Calendario de {data.mes.nombre}">
			{#each SEMANA as d}<div class="g" role="columnheader">{d}</div>{/each}
			{#each celdas as c, i (i)}
				{#if c}
					<div class="celda" role="cell">
						<span class={c.eventos.length ? '' : 'g'}>{c.dia}</span>
						{#each c.eventos as e (e.id)}
							<span class="titulo solo-ancho {e.utopia_id ? '' : 'g'}">{e.titulo}</span>
						{/each}
					</div>
				{:else}
					<div role="cell"></div>
				{/if}
			{/each}
		</div>
		<!-- En teléfono las celdas no tienen lugar para títulos: se listan abajo. -->
		{#if data.delMes.length}
			<table class="e1 solo-telefono"><tbody>
				{#each data.delMes as e (e.id)}
					<tr class={e.utopia_id ? '' : 'g'}><td class="g nw">{diaDelMes(e.fecha)}</td><td>{e.titulo}</td></tr>
				{/each}
			</tbody></table>
		{/if}
	</div>
</section>

<section class="L e2">
	<h2>Siguiente evento</h2>
	{#if !s}
		<p>Por anunciar.</p>
	{:else}
		<div>
			<p>
				{s.titulo}{#if s.detalle}&nbsp; <span class="g">{s.detalle}</span>{/if}<br />
				<span class="g">{fecha(s.fecha)} {dia(s.fecha)} {hora(s.fecha)}</span>
			</p>
			{#if u}
				{#if s.utopia_id !== u.id}
					<p class="e1">Próxima utopía: N°{n2(u.numero)} <span class="g">{fecha(u.fecha)} {dia(u.fecha)} {hora(u.fecha)}</span></p>
				{/if}
				<p>
					{#if u.lugar}Lugar: {u.lugar}{:else}<span class="g">Lugar: se informa 48 h antes a quienes confirmen.</span>{/if}
				</p>
				<form method="POST" action="?/asistencia" use:enhance class="fila">
					<span class="g">{u.confirmados} confirmados</span>
					<input type="hidden" name="utopia_id" value={u.id} />
					<span>
						<button name="estado" value="asistire" class={u.estado === 'asistire' ? 'activo' : ''}>asistiré</button>
						<button name="estado" value="no_asistire" class={u.estado === 'no_asistire' ? 'activo' : ''}>no asistiré</button>
					</span>
				</form>
				{#if form?.error}<p>{form.error}</p>{/if}
			{/if}
		</div>
	{/if}
</section>

<section class="L e2">
	<h2>Foro</h2>
	<div>
		{#if data.hilos.length === 0}
			<p class="g">Todavía no hay hilos.</p>
		{:else}
			<div class="tabla"><table><tbody>
				{#each data.hilos as h (h.id)}
					<tr>
						<td class="hilo"><a href="/foro/{h.id}">{h.titulo}</a></td>
						<td class="g d">{h.respuestas}</td>
						<td class="g d nw">{hace(h.actividad)}</td>
					</tr>
				{/each}
			</tbody></table></div>
		{/if}
		<p class="fila e1"><a class="btn" href="/foro/nuevo">nuevo hilo</a><a href="/foro" class="g">ver el foro</a></p>
	</div>
</section>

<style>
	.mayuscula::first-letter { text-transform: uppercase; }
	.mes { display: grid; grid-template-columns: repeat(7, minmax(0, 1fr)); gap: var(--linea) 16px; max-width: 980px; }
	.celda { min-height: calc(var(--linea) * 2); display: flex; flex-direction: column; overflow-wrap: anywhere; }
	.hilo { min-width: 320px; }
	.solo-telefono { display: none; }
	@media (max-width: 760px) {
		.mes { gap: 0 8px; }
		.celda { min-height: var(--linea); }
		.solo-telefono { display: table; }
		.hilo { min-width: 0; }
	}
</style>
