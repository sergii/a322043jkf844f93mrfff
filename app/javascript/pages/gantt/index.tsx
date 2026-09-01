import { Head } from "@inertiajs/react"

import { Pattern as GanttOne } from "@/components/examples/c-gantt-1"
import { Pattern as GanttTwo } from "@/components/examples/c-gantt-2"
import { Pattern as GanttThree } from "@/components/examples/c-gantt-3"
import { Pattern as GanttFour } from "@/components/examples/c-gantt-4"
import { Pattern as GanttFive } from "@/components/examples/c-gantt-5"
import { Pattern as EngineeringResourceManagement } from "@/components/examples/c-gantt-6"
import AppLayout from "@/layouts/app-layout"
import type { BreadcrumbItem } from "@/types"

const breadcrumbs: BreadcrumbItem[] = [
  {
    title: "Gantt roadmap",
    href: "/gantt",
  },
]

export default function GanttIndex() {
  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Gantt roadmap" />
      <div className="space-y-6">
        <GanttOne />
        <GanttTwo />
        <GanttThree />
        <GanttFour />
        <GanttFive />
        <EngineeringResourceManagement />
      </div>
    </AppLayout>
  )
}
