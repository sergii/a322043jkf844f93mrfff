"use client"

import { useMemo, useRef, useState } from "react"
import { addDays, format, startOfDay, startOfWeek } from "date-fns"
import { PlusIcon } from "lucide-react"

import { Badge, type BadgeProps } from "@/components/reui/badge"
import {
  Gantt,
  type GanttApi,
  type GanttColumn,
} from "@/components/reui/gantt/gantt"
import { GanttNav, GanttToolbar } from "@/components/reui/gantt/gantt-nav"
import type {
  GanttEvent,
  GanttResource,
} from "@/components/reui/gantt/gantt-types"
import { GanttView } from "@/components/reui/gantt/gantt-view"
import {
  Avatar,
  AvatarFallback,
  AvatarImage,
} from "@/components/reui/ui/avatar"
import { Button } from "@/components/reui/ui/button"
import { Card, CardContent } from "@/components/reui/ui/card"
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/reui/ui/tooltip"

type Engineer = {
  name: string
  initials: string
  avatar: string
  discipline: string
  capacity: string
}

type Assignment = {
  owner: string
  status: "Not started" | "In progress" | "At risk" | "Done"
}

type ProjectScheduleData = {
  baselineHours: number
  forecastHours: number
  scopeDeltaHours?: number
  changeLabel?: string
  changeReason?: string
  changeKind?: "scope" | "reassignment"
}

const ENGINEERS: Record<string, Engineer> = {
  "maria-chen": {
    name: "Maria Chen",
    initials: "MC",
    avatar: "https://randomuser.me/api/portraits/women/44.jpg",
    discipline: "Frontend",
    capacity: "80%",
  },
  "samir-khan": {
    name: "Samir Khan",
    initials: "SK",
    avatar: "https://randomuser.me/api/portraits/men/32.jpg",
    discipline: "Backend",
    capacity: "95%",
  },
  "elena-petrova": {
    name: "Elena Petrova",
    initials: "EP",
    avatar: "https://randomuser.me/api/portraits/women/68.jpg",
    discipline: "Platform",
    capacity: "70%",
  },
  "david-okafor": {
    name: "David Okafor",
    initials: "DO",
    avatar: "https://randomuser.me/api/portraits/men/75.jpg",
    discipline: "Mobile",
    capacity: "90%",
  },
  "nina-rossi": {
    name: "Nina Rossi",
    initials: "NR",
    avatar: "https://randomuser.me/api/portraits/women/90.jpg",
    discipline: "QA",
    capacity: "65%",
  },
  "owen-wright": {
    name: "Owen Wright",
    initials: "OW",
    avatar: "https://randomuser.me/api/portraits/men/52.jpg",
    discipline: "DevOps",
    capacity: "85%",
  },
}

const INITIAL_RESOURCES: GanttResource[] = [
  {
    id: "product-engineering",
    title: "Product engineering",
    children: [
      { id: "maria-chen", title: ENGINEERS["maria-chen"].name },
      { id: "samir-khan", title: ENGINEERS["samir-khan"].name },
      { id: "david-okafor", title: ENGINEERS["david-okafor"].name },
    ],
  },
  {
    id: "platform-engineering",
    title: "Platform engineering",
    children: [
      { id: "elena-petrova", title: ENGINEERS["elena-petrova"].name },
      { id: "owen-wright", title: ENGINEERS["owen-wright"].name },
      { id: "nina-rossi", title: ENGINEERS["nina-rossi"].name },
    ],
  },
]

const INITIAL_ASSIGNMENTS: Record<string, Assignment> = {
  "maria-chen": { owner: "maria-chen", status: "In progress" },
  "samir-khan": { owner: "samir-khan", status: "At risk" },
  "elena-petrova": { owner: "elena-petrova", status: "In progress" },
  "david-okafor": { owner: "david-okafor", status: "Not started" },
  "nina-rossi": { owner: "nina-rossi", status: "Done" },
  "owen-wright": { owner: "owen-wright", status: "In progress" },
}

const STATUS_VARIANT: Record<Assignment["status"], BadgeProps["variant"]> = {
  "Not started": "secondary",
  "In progress": "info-light",
  "At risk": "warning-light",
  Done: "success-light",
}

function buildAssignments(anchor: Date): GanttEvent<ProjectScheduleData>[] {
  const week = startOfWeek(startOfDay(anchor), { weekStartsOn: 1 })
  const day = (offset: number) => addDays(week, offset)
  const assignment = (
    resourceId: string,
    title: string,
    start: number,
    duration: number,
    color: string,
    progress: number,
    data: ProjectScheduleData
  ): GanttEvent<ProjectScheduleData> => ({
    id: `assignment-${resourceId}`,
    resourceId,
    title,
    start: day(start),
    end: day(start + duration),
    allDay: true,
    color,
    progress,
    data,
  })

  return [
    assignment("maria-chen", "Candidate portal", -3, 10, "var(--color-blue-500)", 60, { baselineHours: 160, forecastHours: 160 }),
    assignment("samir-khan", "Billing migration", -1, 12, "var(--color-rose-500)", 35, {
      baselineHours: 186,
      forecastHours: 234,
      scopeDeltaHours: 48,
      changeKind: "scope",
      changeLabel: "+48h · +2 working days",
      changeReason: "Additional payment-platform migration work was discovered during implementation.",
    }),
    assignment("elena-petrova", "RLS rollout", -5, 9, "var(--color-violet-500)", 75, { baselineHours: 144, forecastHours: 144 }),
    assignment("david-okafor", "Mobile interview kit", 4, 8, "var(--color-cyan-500)", 10, { baselineHours: 120, forecastHours: 120 }),
    assignment("nina-rossi", "Pipeline regression suite", -8, 7, "var(--color-emerald-500)", 100, { baselineHours: 96, forecastHours: 96 }),
    assignment("owen-wright", "Observability alerts", 1, 10, "var(--color-amber-500)", 45, {
      baselineHours: 160,
      forecastHours: 160,
      changeKind: "reassignment",
      changeLabel: "Reprioritized after week 1",
    }),
  ]
}

const ENGINEERING_BACKLOG = [
  { title: "Accessibility pass", color: "var(--color-teal-500)" },
  { title: "API performance review", color: "var(--color-indigo-500)" },
  { title: "Release readiness", color: "var(--color-orange-500)" },
]

// Daily planned allocation, expressed as a percentage of a normal work day.
// Values above 100 make overbooking visible immediately in the histogram.
const INITIAL_ALLOCATION: Record<string, number[]> = {
  "maria-chen": [70, 80, 80, 70, 60, 0, 0, 80, 80, 80, 65, 50, 0, 0],
  "samir-khan": [100, 110, 115, 110, 100, 0, 0, 105, 110, 100, 90, 80, 0, 0],
  "elena-petrova": [60, 70, 70, 75, 70, 0, 0, 80, 75, 70, 65, 50, 0, 0],
  "david-okafor": [30, 35, 40, 45, 50, 0, 0, 75, 85, 90, 85, 70, 0, 0],
  "nina-rossi": [50, 60, 65, 65, 50, 0, 0, 35, 30, 25, 20, 15, 0, 0],
  "owen-wright": [75, 85, 90, 90, 80, 0, 0, 90, 95, 90, 85, 80, 0, 0],
}

function allocationColor(load: number) {
  if (load > 100) return "rgb(239 68 68)"
  if (load > 80) return "rgb(245 158 11)"
  return "rgb(16 185 129)"
}

function ResourceHistogram({
  boosts,
}: {
  boosts: Record<string, number>
}) {
  const days = useMemo(() => {
    const firstDay = startOfWeek(startOfDay(new Date()), { weekStartsOn: 1 })
    return Array.from({ length: 14 }, (_, index) => addDays(firstDay, index))
  }, [])

  return (
    <Card className="mt-4 overflow-hidden py-0">
      <CardContent className="p-0">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b px-4 py-3">
          <div>
            <h3 className="font-semibold">Resource allocation</h3>
            <p className="text-muted-foreground text-sm">
              Planned engineering load for the next two weeks.
            </p>
          </div>
          <div className="flex items-center gap-3 text-xs text-muted-foreground">
            <span className="flex items-center gap-1.5"><i className="size-2 rounded-sm bg-emerald-500" /> Available</span>
            <span className="flex items-center gap-1.5"><i className="size-2 rounded-sm bg-amber-500" /> Near capacity</span>
            <span className="flex items-center gap-1.5"><i className="size-2 rounded-sm bg-red-500" /> Overbooked</span>
          </div>
        </div>

        <div className="overflow-x-auto">
          <div className="min-w-[920px]">
            <div className="grid grid-cols-[190px_repeat(14,minmax(48px,1fr))] border-b text-xs text-muted-foreground">
              <div className="border-r px-4 py-2 font-medium">Engineer</div>
              {days.map((day) => (
                <div key={day.toISOString()} className="border-r px-1 py-2 text-center">
                  <div>{format(day, "EEE")}</div>
                  <div className="font-medium text-foreground">{format(day, "d")}</div>
                </div>
              ))}
            </div>

            {Object.entries(ENGINEERS).map(([engineerId, engineer]) => {
              const boost = boosts[engineerId] ?? 0
              const allocation = INITIAL_ALLOCATION[engineerId].map((load, index) =>
                index >= 7 && index <= 11 ? load + boost : load
              )

              return (
                <div
                  key={engineerId}
                  className="grid grid-cols-[190px_repeat(14,minmax(48px,1fr))] border-b last:border-b-0"
                >
                  <div className="flex items-center gap-2 border-r px-4 py-2.5">
                    <Avatar className="size-6">
                      <AvatarImage src={engineer.avatar} alt={engineer.name} />
                      <AvatarFallback className="text-[10px]">{engineer.initials}</AvatarFallback>
                    </Avatar>
                    <div className="min-w-0">
                      <div className="truncate text-sm font-medium">{engineer.name}</div>
                      <div className="text-muted-foreground text-xs">{engineer.discipline}</div>
                    </div>
                  </div>
                  {allocation.map((load, index) => {
                    const height = Math.min(load, 120) / 1.2
                    return (
                      <div
                        key={`${engineerId}-${index}`}
                        className="relative flex h-14 items-end border-r bg-muted/15 px-1 pb-1"
                        title={`${engineer.name}: ${load}% allocated on ${format(days[index], "PPP")}`}
                      >
                        <div className="h-full w-full border border-dashed border-muted-foreground/20" />
                        {load > 0 && (
                          <div
                            className="absolute inset-x-1 bottom-1 rounded-sm"
                            style={{
                              height: `${height}%`,
                              backgroundColor: allocationColor(load),
                            }}
                          />
                        )}
                      </div>
                    )
                  })}
                </div>
              )
            })}
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

/**
 * Engineering resource management combines the ReUI examples into one view:
 * team hierarchy and avatar rows, capacity/status columns, progress bars,
 * interactive scheduling, drag resize, resource reordering, and quick
 * backlog assignment. It is intentionally static demo data for now.
 */
export function Pattern() {
  const initialEvents = useMemo(() => buildAssignments(new Date()), [])
  const apiRef = useRef<GanttApi<ProjectScheduleData> | null>(null)
  const addedRef = useRef(0)
  const [resources, setResources] = useState(INITIAL_RESOURCES)
  const [assignments, setAssignments] = useState(INITIAL_ASSIGNMENTS)
  const [allocationBoosts, setAllocationBoosts] = useState<Record<string, number>>({})

  const columns = useMemo<GanttColumn[]>(
    () => [
      {
        id: "discipline",
        title: "Discipline",
        width: 110,
        render: ({ resource, isGroup }) =>
          isGroup ? null : ENGINEERS[resource.id]?.discipline,
      },
      {
        id: "capacity",
        title: "Capacity",
        width: 80,
        render: ({ resource, isGroup }) =>
          isGroup ? null : ENGINEERS[resource.id]?.capacity,
      },
      {
        id: "status",
        title: "Status",
        width: 100,
        render: ({ resource, isGroup }) => {
          if (isGroup) return null
          const status = assignments[resource.id]?.status
          return status ? (
            <Badge variant={STATUS_VARIANT[status]} size="sm">
              {status}
            </Badge>
          ) : null
        },
      },
      {
        id: "variance",
        title: "Plan change",
        width: 145,
        render: ({ resource, isGroup }) => {
          if (isGroup) return null
          const project = initialEvents.find((event) => event.resourceId === resource.id)
          const data = project?.data
          return data?.changeLabel ? (
            <span className="text-xs font-medium text-amber-700 dark:text-amber-400">
              {data.changeLabel}
            </span>
          ) : (
            <span className="text-muted-foreground text-xs">On plan</span>
          )
        },
      },
    ],
    [assignments, initialEvents]
  )

  const addAssignment = () => {
    const api = apiRef.current
    if (!api) return

    const number = addedRef.current++
    const engineerIds = Object.keys(ENGINEERS)
    const engineerId = engineerIds[number % engineerIds.length]
    const backlogItem = ENGINEERING_BACKLOG[number % ENGINEERING_BACKLOG.length]
    const start = addDays(startOfWeek(startOfDay(new Date()), { weekStartsOn: 1 }), 7 + number * 4)

    api.addEvent({
      id: `backlog-${number}`,
      resourceId: engineerId,
      title: backlogItem.title,
      start,
      end: addDays(start, 5),
      allDay: true,
      color: backlogItem.color,
      progress: 0,
      data: { baselineHours: 40, forecastHours: 40 },
    })
    setAssignments((current) => ({
      ...current,
      [engineerId]: { owner: engineerId, status: "Not started" },
    }))
    setAllocationBoosts((current) => ({
      ...current,
      [engineerId]: (current[engineerId] ?? 0) + 15,
    }))
  }

  return (
    <div className="w-full p-4">
      <Card className="w-full py-0">
        <CardContent className="p-0">
          <Gantt<ProjectScheduleData>
            defaultEvents={initialEvents}
            resources={resources}
            columns={columns}
            apiRef={apiRef}
            defaultScale="month"
            offDays
            summaryBars
            treePanel={{ width: 680, nameColumnWidth: 190 }}
            onResourceReorder={({ resources: reordered }) => setResources(reordered)}
            renderResourceLabel={({ resource, isGroup }) => {
              if (isGroup) return undefined
              const engineer = ENGINEERS[resource.id]
              if (!engineer) return resource.title

              return (
                <span className="flex min-w-0 items-center gap-2">
                  <Avatar className="size-5">
                    <AvatarImage src={engineer.avatar} alt={engineer.name} />
                    <AvatarFallback className="text-[10px]">
                      {engineer.initials}
                    </AvatarFallback>
                  </Avatar>
                  <span className="truncate">{engineer.name}</span>
                </span>
              )
            }}
            renderEvent={({ occurrence }) => {
              const data = occurrence.event.data
              // Keep normal work visually quiet. The baseline/forecast overlay
              // exists only to explain a scope change; otherwise the stock
              // Gantt bar communicates planned work and progress clearly.
              if (!data || data.changeKind !== "scope") return undefined
              const baselineShare = Math.min(
                100,
                Math.round((data.baselineHours / data.forecastHours) * 100)
              )
              const hasScopeExtension = baselineShare < 100
              // Progress is always measured against the active forecast, not
              // against the original baseline. A 35%-complete 234h forecast
              // therefore fills 35% of the complete bar, matching every
              // ordinary Gantt bar in this view.
              const progress = Math.min(
                100,
                Math.max(0, occurrence.event.progress ?? 0)
              )

              return (
                <>
                  {/* Cover the stock bar chrome completely. The baseline and
                      forecast become one clean bar rather than nested bars. */}
                  <span className="absolute inset-0 overflow-hidden rounded-[inherit] bg-(--gantt-event-color)/20">
                    <span
                      className="absolute inset-y-0 start-0 bg-(--gantt-event-color)/45"
                      style={{ width: `${baselineShare}%` }}
                    />
                    <span
                      aria-label={`${occurrence.event.progress ?? 0}% complete`}
                      className="absolute inset-y-0 start-0 bg-(--gantt-event-color)/80"
                      style={{ width: `${progress}%` }}
                    />
                    {hasScopeExtension && (
                      <Tooltip>
                        <TooltipTrigger
                          render={
                            <span
                              aria-label={`Scope extension: ${data.changeLabel}`}
                              className="absolute inset-y-0 cursor-help border-s border-dotted border-amber-800/80 bg-[repeating-linear-gradient(135deg,rgba(245,158,11,.42)_0_4px,rgba(245,158,11,.14)_4px_8px)]"
                              style={{
                                insetInlineStart: `${baselineShare}%`,
                                width: `${100 - baselineShare}%`,
                              }}
                            >
                              {data.scopeDeltaHours && (
                                <span className="absolute inset-y-0 start-1 flex items-center text-[10px] font-semibold text-amber-950/80">
                                  +{data.scopeDeltaHours}h
                                </span>
                              )}
                            </span>
                          }
                        />
                        <TooltipContent side="top" className="max-w-64">
                          <div className="font-medium">{occurrence.event.title}</div>
                          <div className="opacity-80">{data.changeLabel}</div>
                          {data.changeReason && (
                            <div className="mt-1 opacity-80">{data.changeReason}</div>
                          )}
                        </TooltipContent>
                      </Tooltip>
                    )}
                  </span>
                  <span className="relative z-10 truncate px-1 text-xs font-medium">
                    {occurrence.event.title}
                  </span>
                </>
              )
            }}
            className="h-[560px] w-full"
          >
            <div className="flex flex-wrap items-center gap-2 border-b pe-3">
              <GanttNav className="min-w-0 flex-1 border-b-0" />
              <GanttToolbar>
                <Button variant="outline" size="sm" onClick={addAssignment}>
                  <PlusIcon className="size-4" aria-hidden="true" />
                  Assign backlog task
                </Button>
              </GanttToolbar>
            </div>
            <GanttView />
          </Gantt>
        </CardContent>
      </Card>
      <ResourceHistogram boosts={allocationBoosts} />
    </div>
  )
}
