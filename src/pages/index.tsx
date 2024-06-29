import { useEffect, useState } from 'react'
import { invoke } from '@tauri-apps/api/tauri'
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion'

type Channel = {
  name: string
}

type Fixture = {
  name: string
  channels: Channel[]
}

function Fixture({ fixture }: { fixture: Fixture }) {
  return (
    <AccordionItem value={fixture.name}>
      <AccordionTrigger>{fixture.name}</AccordionTrigger>
      <AccordionContent>
          {fixture.channels.map(channel => channel.name).join(', ')}
      </AccordionContent>
    </AccordionItem>
  )
}

export default function Index() {
  const [fixtures, setFixtures] = useState<Fixture[] | null>(null)

  async function getFixtures() {
    const res: Fixture[] = await invoke('get_fixtures')
    return res
  }

  useEffect(() => {
    getFixtures().then(setFixtures)
  }, [])

  if (!fixtures) return <div>Loading...</div>

  return (
    <>
      <h1 className='scroll-m-20 text-4xl font-extrabold tracking-tight lg:text-5xl'>Fixtures</h1>
      <Accordion type='single' collapsible className='w-full'>
        {fixtures.map((fixture, i) => (
          <Fixture key={i} fixture={fixture} />
        ))}
      </Accordion>
    </>
  )
}
