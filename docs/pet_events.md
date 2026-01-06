# Pet Events Feature

The Pet Events feature allows users to record and manage various pet-related events with offline-first persistence using Hive.

## Data Models

### PetEventModel
- `id`: Unique identifier (UUID).
- `petId`: Reference to the pet.
- `group`: Event group (food, health, elimination, grooming, activity, behavior, schedule, media, metrics).
- `type`: Subtype within the group.
- `title`: Event title (custom or auto-generated).
- `notes`: Multiline notes.
- `timestamp`: Date and time of the event.
- `includeInPdf`: Boolean toggle for reporting.
- `data`: Extensible payload for specific group fields.
- `attachments`: List of `AttachmentModel`.
- `isDeleted`: Soft-delete flag.

### AttachmentModel
- `id`: Unique identifier.
- `kind`: image, video, audio, or file.
- `path`: Local path to the file.
- `mimeType`: MIME type of the file.
- `size`: File size in bytes.
- `hash`: SHA-256 hash for duplicate detection.

## Usage

### Recording an Event
Open the `PetEventBottomSheet` from the pet card using the group's icon in the `EventActionBar`.

### Repository
Use `PetEventRepository` to interact with the data:
- `addEvent(PetEventModel)`
- `listEventsByPet(petId)`
- `listTodayCountByGroup(petId)`
- `updateEvent(PetEventModel)`
- `deleteEventSoft(eventId)`

## Initialization
Initialized automatically via `SimpleAuthService` during secure data setup.
Box name: `pet_events_journal`.
Adapters: `AttachmentModelAdapter` (40), `PetEventModelAdapter` (41).
