'use client';

import { useId, useMemo, useRef, useState } from 'react';

import { formatCompact, formatDayLabel, formatNumber } from '@/lib/format';
import type { DistributionSlice, TimeSeriesPoint } from '@/lib/types';

/* ==========================================================================
   Hand-rolled SVG charts. No chart library, no canvas.

   Rules enforced here, from the dataviz method:
   - at most TWO categorical series per chart (the validated green/blue pair)
   - one y-axis, ever — differently-scaled measures get separate charts
   - a legend whenever there are 2 series; a single series is named by the title
   - thin marks: 2px lines, 8px hover markers, recessive grid
   - identity is never colour-alone — every chart ships a table view
   ========================================================================== */

const PLOT = {
  width: 760,
  height: 240,
  top: 14,
  right: 18,
  bottom: 30,
  left: 46,
};

const innerWidth = PLOT.width - PLOT.left - PLOT.right;
const innerHeight = PLOT.height - PLOT.top - PLOT.bottom;

export interface ChartSeries {
  key: string;
  label: string;
  /** A CSS custom property reference — `var(--series-1)` or `var(--series-2)`. */
  color: string;
  points: TimeSeriesPoint[];
}

/**
 * Picks a round tick interval and extends the axis to a multiple of it, so
 * every gridline is a whole number. Splitting the peak into fixed fractions
 * instead would print ticks like "37.5" on a count of people.
 */
function niceScale(peak: number): { max: number; ticks: number[] } {
  if (peak <= 0) return { max: 1, ticks: [0, 1] };
  const rough = peak / 4;
  const magnitude = 10 ** Math.floor(Math.log10(rough));
  const normalized = rough / magnitude;
  const step =
    (normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10) *
    magnitude;
  const max = Math.ceil(peak / step) * step;
  const ticks: number[] = [];
  for (let value = 0; value <= max + step / 2; value += step) {
    ticks.push(Number(value.toFixed(6)));
  }
  return { max, ticks };
}

function TableView({
  caption,
  columns,
  rows,
}: {
  caption: string;
  columns: string[];
  rows: (string | number)[][];
}) {
  return (
    <details className="chart__table">
      <summary>View {caption} as a table</summary>
      <div className="table-scroll">
        <table className="table">
          <caption className="sr-only">{caption}</caption>
          <thead>
            <tr>
              {columns.map((column) => (
                <th key={column} scope="col">
                  {column}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, index) => (
              <tr key={index}>
                {row.map((cell, cellIndex) => (
                  <td key={cellIndex} className="numeric">
                    {cell}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </details>
  );
}

/* ---------------------------------------------------------- area / line */

export function TimeSeriesChart({
  title,
  subtitle,
  series,
}: {
  title: string;
  subtitle?: string;
  series: ChartSeries[];
}) {
  const gradientId = useId();
  const svgRef = useRef<SVGSVGElement>(null);
  const [hover, setHover] = useState<number | null>(null);

  // Two series is the validated ceiling; a third would need a re-validated
  // palette, so extras are dropped loudly rather than silently recoloured.
  const shown = series.slice(0, 2);
  const length = Math.max(0, ...shown.map((entry) => entry.points.length));

  const { max, ticks } = useMemo(() => {
    const peak = Math.max(
      0,
      ...shown.flatMap((entry) => entry.points.map((point) => point.value)),
    );
    return niceScale(peak);
  }, [shown]);

  if (length === 0) {
    return (
      <figure className="chart">
        <figcaption className="chart__head">
          <h3 className="h3">{title}</h3>
          {subtitle ? <p className="muted chart__sub">{subtitle}</p> : null}
        </figcaption>
        <p className="chart__empty">No data for this period yet.</p>
      </figure>
    );
  }

  const x = (index: number): number =>
    length === 1
      ? PLOT.left + innerWidth / 2
      : PLOT.left + (index / (length - 1)) * innerWidth;
  const y = (value: number): number =>
    PLOT.top + innerHeight - (value / max) * innerHeight;

  const handleMove = (event: React.PointerEvent<SVGSVGElement>) => {
    const svg = svgRef.current;
    if (!svg) return;
    const bounds = svg.getBoundingClientRect();
    // Map the pointer from screen space into the fixed viewBox space.
    const local =
      ((event.clientX - bounds.left) / bounds.width) * PLOT.width - PLOT.left;
    const ratio = innerWidth === 0 ? 0 : local / innerWidth;
    const index = Math.round(ratio * (length - 1));
    setHover(Math.min(length - 1, Math.max(0, index)));
  };

  const hoveredDate =
    hover === null ? null : (shown[0]?.points[hover]?.date ?? null);

  return (
    <figure className="chart">
      <figcaption className="chart__head">
        <div>
          <h3 className="h3">{title}</h3>
          {subtitle ? <p className="muted chart__sub">{subtitle}</p> : null}
        </div>
        {shown.length > 1 ? (
          <ul className="legend">
            {shown.map((entry) => (
              <li key={entry.key}>
                <span
                  className="legend__swatch"
                  style={{ backgroundColor: entry.color }}
                  aria-hidden="true"
                />
                {entry.label}
              </li>
            ))}
          </ul>
        ) : null}
      </figcaption>

      <div className="chart__plot">
        <svg
          ref={svgRef}
          viewBox={`0 0 ${PLOT.width} ${PLOT.height}`}
          className="chart__svg"
          role="img"
          aria-label={`${title}. ${shown
            .map((entry) => `${entry.label}, peak ${formatNumber(max)}`)
            .join('. ')}`}
          onPointerMove={handleMove}
          onPointerLeave={() => setHover(null)}
        >
          <defs>
            {shown.map((entry, index) => (
              <linearGradient
                key={entry.key}
                id={`${gradientId}-${index}`}
                x1="0"
                y1="0"
                x2="0"
                y2="1"
              >
                <stop offset="0%" stopColor={entry.color} stopOpacity="0.26" />
                <stop offset="100%" stopColor={entry.color} stopOpacity="0.02" />
              </linearGradient>
            ))}
          </defs>

          {/* Grid and axis stay recessive — they orient, they don't compete. */}
          {ticks.map((tick) => (
            <g key={tick}>
              <line
                x1={PLOT.left}
                x2={PLOT.width - PLOT.right}
                y1={y(tick)}
                y2={y(tick)}
                stroke="var(--grid-line)"
                strokeWidth="1"
              />
              <text
                x={PLOT.left - 10}
                y={y(tick) + 4}
                textAnchor="end"
                className="chart__tick"
              >
                {formatCompact(tick)}
              </text>
            </g>
          ))}

          {shown.map((entry, index) => {
            const points = entry.points;
            if (points.length === 0) return null;
            const line = points
              .map(
                (point, pointIndex) =>
                  `${pointIndex === 0 ? 'M' : 'L'} ${x(pointIndex)} ${y(point.value)}`,
              )
              .join(' ');
            const area = `${line} L ${x(points.length - 1)} ${
              PLOT.top + innerHeight
            } L ${x(0)} ${PLOT.top + innerHeight} Z`;
            return (
              <g key={entry.key}>
                <path d={area} fill={`url(#${gradientId}-${index})`} />
                <path
                  d={line}
                  fill="none"
                  stroke={entry.color}
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </g>
            );
          })}

          {/* x labels: first, middle and last only — a label per point is noise */}
          {[0, Math.floor((length - 1) / 2), length - 1]
            .filter((value, index, all) => all.indexOf(value) === index)
            .map((index) => {
              const date = shown[0]?.points[index]?.date;
              if (!date) return null;
              return (
                <text
                  key={index}
                  x={x(index)}
                  y={PLOT.height - 10}
                  textAnchor={
                    index === 0 ? 'start' : index === length - 1 ? 'end' : 'middle'
                  }
                  className="chart__tick"
                >
                  {formatDayLabel(date)}
                </text>
              );
            })}

          {hover !== null ? (
            <g pointerEvents="none">
              <line
                x1={x(hover)}
                x2={x(hover)}
                y1={PLOT.top}
                y2={PLOT.top + innerHeight}
                stroke="var(--axis-line)"
                strokeWidth="1"
                strokeDasharray="3 3"
              />
              {shown.map((entry) => {
                const point = entry.points[hover];
                if (!point) return null;
                return (
                  <circle
                    key={entry.key}
                    cx={x(hover)}
                    cy={y(point.value)}
                    r="4.5"
                    fill={entry.color}
                    /* A 2px surface ring keeps overlapping markers separable. */
                    stroke="var(--glass-bg-opaque)"
                    strokeWidth="2"
                  />
                );
              })}
            </g>
          ) : null}
        </svg>

        {hover !== null && hoveredDate ? (
          <div
            className="chart__tooltip"
            style={{
              left: `${(x(hover) / PLOT.width) * 100}%`,
            }}
            role="status"
          >
            <p className="chart__tooltip-date">{formatDayLabel(hoveredDate)}</p>
            {shown.map((entry) => (
              <p key={entry.key} className="chart__tooltip-row">
                <span
                  className="legend__swatch"
                  style={{ backgroundColor: entry.color }}
                  aria-hidden="true"
                />
                {entry.label}
                <strong className="numeric">
                  {formatNumber(entry.points[hover]?.value ?? 0)}
                </strong>
              </p>
            ))}
          </div>
        ) : null}
      </div>

      <TableView
        caption={title}
        columns={['Date', ...shown.map((entry) => entry.label)]}
        rows={Array.from({ length }, (_, index) => [
          shown[0]?.points[index]?.date ?? '',
          ...shown.map((entry) => entry.points[index]?.value ?? 0),
        ])}
      />
    </figure>
  );
}

/* --------------------------------------------------------------- bar list */

/**
 * Horizontal bars for a distribution. Magnitude is the job, so this is one
 * hue at one step — not a categorical rainbow across categories that have no
 * identity relationship to each other.
 */
export function BarList({
  title,
  slices,
  limit = 8,
  emptyLabel = 'No data yet.',
}: {
  title: string;
  slices: DistributionSlice[];
  limit?: number;
  emptyLabel?: string;
}) {
  const shown = slices.slice(0, limit);
  const max = Math.max(1, ...shown.map((slice) => slice.value));
  const total = slices.reduce((sum, slice) => sum + slice.value, 0);

  return (
    <figure className="chart">
      <figcaption className="chart__head">
        <div>
          <h3 className="h3">{title}</h3>
          <p className="muted chart__sub">
            {total > 0
              ? `${formatNumber(total)} total across ${slices.length} ${
                  slices.length === 1 ? 'value' : 'values'
                }`
              : 'Nothing recorded yet'}
          </p>
        </div>
      </figcaption>

      {shown.length === 0 ? (
        <p className="chart__empty">{emptyLabel}</p>
      ) : (
        <ul className="barlist">
          {shown.map((slice) => (
            <li key={slice.label} className="barlist__row">
              <span className="barlist__label" title={slice.label}>
                {slice.label}
              </span>
              <span className="barlist__track">
                <span
                  className="barlist__fill"
                  style={{ width: `${Math.max(2, (slice.value / max) * 100)}%` }}
                />
              </span>
              <span className="barlist__value numeric">
                {formatNumber(slice.value)}
              </span>
            </li>
          ))}
        </ul>
      )}

      {slices.length > limit ? (
        <p className="muted chart__note">
          Showing the top {limit} of {slices.length}.
        </p>
      ) : null}

      {shown.length > 0 ? (
        <TableView
          caption={title}
          columns={['Value', 'Count']}
          rows={slices.map((slice) => [slice.label, slice.value])}
        />
      ) : null}
    </figure>
  );
}

/* ------------------------------------------------------------- stat tile */

export function StatTile({
  label,
  value,
  hint,
  tone = 'neutral',
}: {
  label: string;
  value: string;
  hint?: string;
  tone?: 'neutral' | 'good' | 'warning' | 'critical';
}) {
  return (
    <div className={`stat stat--${tone}`}>
      <p className="eyebrow">{label}</p>
      <p className="stat__value numeric">{value}</p>
      {hint ? <p className="muted stat__hint">{hint}</p> : null}
    </div>
  );
}

/** A single-series magnitude bar used inside stat groups. */
export function Sparkbar({
  points,
  label,
}: {
  points: TimeSeriesPoint[];
  label: string;
}) {
  const max = Math.max(1, ...points.map((point) => point.value));
  return (
    <div
      className="sparkbar"
      role="img"
      aria-label={`${label}: ${points.length} days, peak ${formatNumber(max)}`}
    >
      {points.map((point) => (
        <span
          key={point.date}
          className="sparkbar__bar"
          style={{ height: `${Math.max(4, (point.value / max) * 100)}%` }}
          title={`${formatDayLabel(point.date)}: ${formatNumber(point.value)}`}
        />
      ))}
    </div>
  );
}
