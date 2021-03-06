require 'airport'

describe Airport do

  subject(:airport)       { Airport.new }
  let(:plane)             { double("Plane", :land => :landed, :takeoff => :airborne) }
  let(:sunny_weather)     { allow_any_instance_of(Airport).to receive(:weather).and_return('sunny') }
  let(:stormy_weather)    { allow_any_instance_of(Airport).to receive(:weather).and_return('stormy') }

  # EXPECTED ERROR MESSAGES
  let(:airport_full)      { 'Airport is at capacity' }
  let(:plane_not_here)    { 'Plane is not at this airport' }
  let(:stormy_error)      { 'Weather is stormy and too unsafe' }

  def full_airport(capacity)
    sunny_weather
    plane = double("Plane", :land => :landed, :takeoff => :airborne)
    airport = Airport.new(capacity)
    capacity.times { airport.clear_landing(plane) }
    airport
  end

  describe '#create_plane(plane)' do
    it { should respond_to(:create_plane).with(0).arguments }

    it 'adds a new plane to the airport if it has capacity' do
      new_plane = airport.create_plane
      expect(airport.has_plane?(new_plane)).to eq true
      expect { airport.create_plane }.to change { airport.planes.count }.by(1)
    end

    it 'returns the new plane that was added' do
      expect(airport.create_plane).to be_an_instance_of(Plane)
    end

    it "raises error and doesn't store plane if airport is full" do
      airport = full_airport(3)

      expect { airport.create_plane }.to raise_error(airport_full)
      expect { airport.create_plane rescue nil }.not_to change(airport, :planes)
    end
  end

  describe '#clear_landing(plane)' do
    it { should respond_to(:clear_landing).with(1).argument }

    context 'when airport has capacity' do
      context 'when weather is sunny' do
        before do
          sunny_weather
        end

        it 'sends a request to the plane to land' do
          expect(plane).to receive(:land).once.with(no_args)
          airport.clear_landing(plane)
        end

        it 'stores the plane if plane lands without error' do
          airport.clear_landing(plane)
          expect(airport.has_plane?(plane)).to eq true
        end

        it 'stores all planes that are currently landed there' do
          qf1 = double("Plane", :land => :landed, :takeoff => :airborne)
          ba0016 = double("Plane", :land => :landed, :takeoff => :airborne)

          [qf1, ba0016].each { |plane| airport.clear_landing(plane) }
          expect(airport.has_plane?(qf1)).to eq true
          expect(airport.has_plane?(ba0016)).to eq true
        end

        it "doesn't store plane if the plane throws an error" do
          allow(plane).to receive(:land).and_raise('Plane is already landed')
          expect { airport.clear_landing(plane) }.to raise_error(RuntimeError)
          expect { airport.clear_landing(plane) rescue nil }.not_to change(airport, :planes)
        end
      end

      context 'when weather is stormy' do
        it 'raises an error and retains plane at airport' do
          stormy_weather
          expect { airport.clear_landing(plane) }.to raise_error(stormy_error)
        end
      end
    end

    context 'when airport is full with default capacity' do
      it "raises error and doesn't store plane" do
        airport = full_airport(Airport::DEFAULT_CAPACITY)

        expect { airport.clear_landing(plane) }.to raise_error(airport_full)
        expect(airport.has_plane?(plane)).to eq false
      end
    end

    context 'when airport is full with lower capacity set' do
      it 'limits planes to the lower capacity' do
        small_airport = full_airport(Airport::DEFAULT_CAPACITY / 5)

        expect { small_airport.clear_landing(plane) }.to raise_error(airport_full)
        expect(small_airport.has_plane?(plane)).to eq false
      end
    end

    context 'when airport is full with higher capacity set' do
      it 'limits planes at the higher capacity' do
        large_airport = full_airport(Airport::DEFAULT_CAPACITY * 2)

        expect { large_airport.clear_landing(plane) }.to raise_error(airport_full)
        expect(large_airport.has_plane?(plane)).to eq false
      end
    end
  end

  describe '#clear_takeoff(plane)' do
    it { should respond_to(:clear_takeoff).with(1).argument }

    context 'when plane is at the airport' do
      before do
        sunny_weather
        airport.clear_landing(plane)
      end

      context 'when weather is sunny' do
        before do
          sunny_weather
        end

        it 'sends a request to the plane to takeoff' do
          expect(plane).to receive(:takeoff).once.with(no_args)
          airport.clear_takeoff(plane)
        end

        it 'releases plane if plane takes off without error' do
          airport.clear_takeoff(plane)
          expect(airport.has_plane?(plane)).to eq false
        end

        it "doesn't release plane if the plane throws an error" do
          allow(plane).to receive(:takeoff).and_raise('Plane is already airborne')
          expect { airport.clear_takeoff(plane) }.to raise_error(RuntimeError)
          expect { airport.clear_takeoff(plane) rescue nil }.not_to change(airport, :planes)
        end
      end

      context 'when weather is stormy' do
        before do
          stormy_weather
        end

        it 'raises an error and retains plane at airport' do
          expect { airport.clear_takeoff(plane) }.to raise_error(stormy_error)
          expect(airport.has_plane?(plane)).to eq true
        end
      end
    end

    context 'when plane is not at the airport' do
      it 'raises an error' do
        expect { airport.clear_takeoff(plane) }.to raise_error(plane_not_here)
      end
    end
  end
end
