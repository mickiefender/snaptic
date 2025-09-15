-- Snaptic NFC Ticketing System Database Schema
-- Run this SQL in your Supabase SQL editor

-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" = 'your-jwt-secret';

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('attendee', 'organizer')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create events table
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id UUID REFERENCES profiles(id) NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  image_url TEXT NOT NULL,
  location TEXT,
  ticket_price DECIMAL(10,2),
  max_attendees INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create tickets table
CREATE TABLE IF NOT EXISTS tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  uid TEXT NOT NULL UNIQUE, -- NFC UID
  event_id UUID REFERENCES events(id) NOT NULL,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'checked_in')) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  checked_in_at TIMESTAMPTZ
);

-- Create checkers table (for organizers to authorize people to scan tickets)
CREATE TABLE IF NOT EXISTS checkers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id UUID REFERENCES profiles(id) NOT NULL,
  checker_id UUID REFERENCES profiles(id) NOT NULL,
  event_id UUID REFERENCES events(id),
  authorized_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organizer_id, checker_id, event_id)
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkers ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" 
  ON profiles FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
  ON profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Events policies
CREATE POLICY "Anyone can view events" 
  ON events FOR SELECT 
  TO authenticated 
  USING (true);

CREATE POLICY "Organizers can create events" 
  ON events FOR INSERT 
  TO authenticated 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'organizer'
    )
  );

CREATE POLICY "Organizers can update own events" 
  ON events FOR UPDATE 
  TO authenticated 
  USING (organizer_id = auth.uid());

CREATE POLICY "Organizers can delete own events" 
  ON events FOR DELETE 
  TO authenticated 
  USING (organizer_id = auth.uid());

-- Tickets policies
CREATE POLICY "Users can view own tickets" 
  ON tickets FOR SELECT 
  TO authenticated 
  USING (user_id = auth.uid());

CREATE POLICY "Organizers can view tickets for their events" 
  ON tickets FOR SELECT 
  TO authenticated 
  USING (
    EXISTS (
      SELECT 1 FROM events 
      WHERE events.id = tickets.event_id 
      AND events.organizer_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own tickets" 
  ON tickets FOR INSERT 
  TO authenticated 
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Organizers can update tickets for their events" 
  ON tickets FOR UPDATE 
  TO authenticated 
  USING (
    EXISTS (
      SELECT 1 FROM events 
      WHERE events.id = tickets.event_id 
      AND events.organizer_id = auth.uid()
    )
  );

-- Checkers policies
CREATE POLICY "Organizers can manage checkers" 
  ON checkers FOR ALL 
  TO authenticated 
  USING (organizer_id = auth.uid())
  WITH CHECK (organizer_id = auth.uid());

CREATE POLICY "Authorized checkers can view" 
  ON checkers FOR SELECT 
  TO authenticated 
  USING (checker_id = auth.uid());

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON profiles 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_events_updated_at 
  BEFORE UPDATE ON events 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Create function to handle user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'attendee')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Create storage bucket for event images (run this in Supabase dashboard -> Storage)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('event-images', 'event-images', true);

-- Storage policies for event images
-- CREATE POLICY "Authenticated users can view event images"
--   ON storage.objects FOR SELECT
--   TO authenticated
--   USING (bucket_id = 'event-images');

-- CREATE POLICY "Organizers can upload event images"
--   ON storage.objects FOR INSERT
--   TO authenticated
--   WITH CHECK (
--     bucket_id = 'event-images' AND
--     EXISTS (
--       SELECT 1 FROM profiles
--       WHERE id = auth.uid()
--       AND role = 'organizer'
--     )
--   );

-- Sample data (optional - for testing)
-- Note: You'll need to create users through the Supabase auth first

-- Insert sample organizer profile (replace with actual user ID)
-- INSERT INTO profiles (id, name, email, role) 
-- VALUES ('00000000-0000-0000-0000-000000000001', 'John Organizer', 'organizer@test.com', 'organizer');

-- Insert sample attendee profile (replace with actual user ID)
-- INSERT INTO profiles (id, name, email, role) 
-- VALUES ('00000000-0000-0000-0000-000000000002', 'Jane Attendee', 'attendee@test.com', 'attendee');

-- Insert sample event
-- INSERT INTO events (organizer_id, title, description, date, image_url, location, ticket_price, max_attendees)
-- VALUES (
--   '00000000-0000-0000-0000-000000000001',
--   'TIDAL RAVE - The New Wave SEQUEL',
--   'The music takes control & the night wave sets Ujira Beats in motion. Join us for an unforgettable night.',
--   '2024-12-25 20:00:00+00',
--   'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500',
--   'Lagos, Nigeria',
--   25.00,
--   500
-- );

-- Insert sample ticket
-- INSERT INTO tickets (uid, event_id, user_id, status)
-- SELECT 
--   'A1B2C3D4E5F6',
--   e.id,
--   '00000000-0000-0000-0000-000000000002',
--   'active'
-- FROM events e
-- WHERE e.title = 'TIDAL RAVE - The New Wave SEQUEL';